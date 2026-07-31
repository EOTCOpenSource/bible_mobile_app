import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum AudioState { stopped, buffering, playing, paused }

class AudioService {
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();

  final AudioPlayer _player = AudioPlayer();
  
  final ValueNotifier<AudioState> stateNotifier = ValueNotifier(AudioState.stopped);
  final ValueNotifier<String?> currentTitleNotifier = ValueNotifier(null);
  final ValueNotifier<int?> currentVerseIndexNotifier = ValueNotifier(null);

  /// Pass these at build time:
  ///   flutter run --dart-define=ADDIS_AI_API_KEY=sk_...
  static const String _apiKey = String.fromEnvironment('ADDIS_AI_API_KEY');
  static const String _apiUrl = String.fromEnvironment(
    'ADDIS_AI_TTS_URL',
    defaultValue: 'https://api.addisassistant.com/api/v1/audio',
  );

  bool _isInitialized = false;

  void _initIfNeeded() {
    if (_isInitialized) return;
    
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
        stateNotifier.value = AudioState.buffering;
      } else if (processingState == ProcessingState.ready) {
        stateNotifier.value = isPlaying ? AudioState.playing : AudioState.paused;
      } else if (processingState == ProcessingState.completed) {
        stateNotifier.value = AudioState.stopped;
        currentTitleNotifier.value = null;
        currentVerseIndexNotifier.value = null;
      }
    });

    _player.currentIndexStream.listen((index) {
      currentVerseIndexNotifier.value = index;
    });

    _isInitialized = true;
  }

  Future<void> startChapter({
    required String title,
    required List<String> verses,
  }) async {
    _initIfNeeded();
    
    if (_apiKey.isEmpty) {
      debugPrint('AudioService: ADDIS_AI_API_KEY not set.');
      stop();
      return;
    }

    await _player.stop();
    stateNotifier.value = AudioState.buffering;
    currentTitleNotifier.value = title;
    currentVerseIndexNotifier.value = null;

    try {
      // Set calm, slow 0.88x pace
      await _player.setSpeed(0.88);

      final dir = await getTemporaryDirectory();
      final audioSources = <AudioSource>[];

      debugPrint("[AudioService] Generating verse-by-verse audio for ${verses.length} verses...");

      for (var i = 0; i < verses.length; i++) {
        var verseText = verses[i].trim();
        if (!verseText.endsWith('።') && !verseText.endsWith('.')) {
          verseText = '$verseText ።';
        }

        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'x-api-key': _apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'text': verseText,
            'language': 'am',
            'voice': 'am-dawit',
            'voice_id': 'am-dawit',
            'speaker': 'am-dawit',
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final audioBase64 = json['audio'] as String?;
          
          if (audioBase64 != null && audioBase64.isNotEmpty) {
            final bytes = base64Decode(audioBase64);
            final file = File('${dir.path}/verse_audio_$i.mp3');
            await file.writeAsBytes(bytes);
            audioSources.add(AudioSource.file(file.path));
          }
        } else {
          debugPrint("Addis AI Error on verse $i: ${response.statusCode} - ${response.body}");
        }
      }

      if (audioSources.isEmpty) {
        debugPrint("[AudioService] No audio sources generated.");
        stop();
        return;
      }

      final playlist = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlist);
      await _player.play();
    } catch (e, stack) {
      debugPrint("Audio Error: $e\n$stack");
      stop();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    stateNotifier.value = AudioState.stopped;
    currentTitleNotifier.value = null;
    currentVerseIndexNotifier.value = null;
  }
}
