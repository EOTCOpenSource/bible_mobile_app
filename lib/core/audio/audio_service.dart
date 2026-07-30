import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AudioState { stopped, playing, paused }

class AudioService {
  AudioService._internal() {
    _initTts();
  }
  static final AudioService instance = AudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  final ValueNotifier<AudioState> stateNotifier =
      ValueNotifier<AudioState>(AudioState.stopped);
  final ValueNotifier<int> currentVerseIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String?> currentTitleNotifier = ValueNotifier<String?>(null);

  List<String> _currentVerses = [];
  int _currentIndex = 0;
  String _currentTitle = '';
  String _currentLanguage = 'am-ET';

  AudioState get state => stateNotifier.value;
  bool get isPlaying => state == AudioState.playing;
  bool get isPaused => state == AudioState.paused;
  bool get isStopped => state == AudioState.stopped;

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      _onVerseCompleted();
    });

    _flutterTts.setErrorHandler((msg) {
      if (kDebugMode) {
        print('[AudioService] TTS Error: $msg');
      }
      stop();
    });
  }

  /// Configures and starts reading a list of verses (e.g. a chapter)
  Future<void> startChapter({
    required String title,
    required List<String> verses,
    String language = 'am-ET',
    int startVerseIndex = 0,
  }) async {
    await stop();
    if (verses.isEmpty) return;

    _currentTitle = title;
    _currentVerses = verses;
    _currentIndex = startVerseIndex.clamp(0, verses.length - 1);
    _currentLanguage = language;

    currentTitleNotifier.value = _currentTitle;
    currentVerseIndexNotifier.value = _currentIndex;

    await _flutterTts.setLanguage(_currentLanguage);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);

    await _speakCurrentVerse();
  }

  Future<void> _speakCurrentVerse() async {
    if (_currentIndex < 0 || _currentIndex >= _currentVerses.length) {
      await stop();
      return;
    }

    stateNotifier.value = AudioState.playing;
    currentVerseIndexNotifier.value = _currentIndex;

    final verseText = _currentVerses[_currentIndex];
    await _flutterTts.speak(verseText);
  }

  void _onVerseCompleted() async {
    if (state != AudioState.playing) return;

    if (_currentIndex + 1 < _currentVerses.length) {
      _currentIndex++;
      await _speakCurrentVerse();
    } else {
      await stop();
    }
  }

  Future<void> pause() async {
    if (state == AudioState.playing) {
      await _flutterTts.pause();
      stateNotifier.value = AudioState.paused;
    }
  }

  Future<void> resume() async {
    if (state == AudioState.paused) {
      stateNotifier.value = AudioState.playing;
      await _speakCurrentVerse();
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    stateNotifier.value = AudioState.stopped;
    _currentIndex = 0;
    currentVerseIndexNotifier.value = 0;
  }
}
