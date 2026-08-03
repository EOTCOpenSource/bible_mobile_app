import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'addis_tts_client.dart';

enum AudioState { stopped, buffering, playing, paused }

/// Why [AudioService.startChapter] did not start, so the caller can route the
/// user somewhere useful instead of leaving a dead button.
enum StartAudioResult {
  started,

  /// No key saved — send the user to the voice settings page.
  missingApiKey,

  /// A key is saved but the catalog gave us no voice to read with.
  noVoiceAvailable,

  /// The key was rejected (401/403).
  invalidApiKey,

  /// Network or server failure; [AudioService.lastError] has the detail.
  failed,

  /// Superseded by a newer request, or stopped mid-generation.
  cancelled,
}

/// Verse-by-verse playback of a chapter through the Addis AI voice API.
///
/// Two things matter here beyond the obvious:
///
/// * Generation is billed to the *user's* key, so the first verse starts
///   playing as soon as it is ready and the rest are appended while it plays.
///   Waiting for a whole chapter would mean minutes of silence on something
///   like Psalm 119 (176 verses).
/// * Every run carries a generation number. [stop] bumps it, so a run that is
///   still fetching notices it has been superseded and neither queues more
///   audio nor starts playing.
class AudioService {
  AudioService._privateConstructor();
  static final AudioService instance = AudioService._privateConstructor();

  final AudioPlayer _player = AudioPlayer();
  final AddisTtsClient _client = AddisTtsClient();

  final ValueNotifier<AudioState> stateNotifier =
      ValueNotifier(AudioState.stopped);
  final ValueNotifier<String?> currentTitleNotifier = ValueNotifier(null);
  final ValueNotifier<int?> currentVerseIndexNotifier = ValueNotifier(null);

  /// Detail for [StartAudioResult.failed], for surfacing in a snackbar.
  String? lastError;

  bool _isInitialized = false;

  /// Incremented on every start and every stop. A run whose token no longer
  /// matches has been superseded and must not touch the player.
  int _generation = 0;

  void _initIfNeeded() {
    if (_isInitialized) return;

    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
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

  /// Reads [verses] aloud with [voiceId], using the user's own [apiKey].
  ///
  /// Returns as soon as the outcome is known; audio for later verses keeps
  /// arriving in the background.
  Future<StartAudioResult> startChapter({
    required String title,
    required List<String> verses,
    required String? apiKey,
    required String? voiceId,
    String language = 'am',
  }) async {
    _initIfNeeded();
    lastError = null;

    if (apiKey == null || apiKey.isEmpty) return StartAudioResult.missingApiKey;
    if (voiceId == null || voiceId.isEmpty) {
      return StartAudioResult.noVoiceAvailable;
    }
    if (verses.isEmpty) return StartAudioResult.noVoiceAvailable;

    final token = ++_generation;

    await _player.stop();
    stateNotifier.value = AudioState.buffering;
    currentTitleNotifier.value = title;
    currentVerseIndexNotifier.value = null;

    try {
      // Calm, slightly slow reading pace.
      await _player.setSpeed(0.88);

      final firstUrl = await _client.generate(
        apiKey: apiKey,
        text: _prepare(verses.first),
        voiceId: voiceId,
        language: language,
      );
      if (token != _generation) return StartAudioResult.cancelled;

      await _player.setAudioSources([AudioSource.uri(firstUrl)]);
      if (token != _generation) return StartAudioResult.cancelled;
      await _player.play();

      // The rest stream in behind the first verse; a failure past this point
      // shortens the chapter rather than killing playback.
      if (verses.length > 1) {
        unawaited(_appendRemaining(
          token: token,
          verses: verses,
          apiKey: apiKey,
          voiceId: voiceId,
          language: language,
        ));
      }
      return StartAudioResult.started;
    } on AddisTtsException catch (e) {
      if (token != _generation) return StartAudioResult.cancelled;
      lastError = e.message;
      await stop();
      return e.isAuthFailure
          ? StartAudioResult.invalidApiKey
          : StartAudioResult.failed;
    } on Object catch (e) {
      if (token != _generation) return StartAudioResult.cancelled;
      lastError = e.toString();
      await stop();
      return StartAudioResult.failed;
    }
  }

  Future<void> _appendRemaining({
    required int token,
    required List<String> verses,
    required String apiKey,
    required String voiceId,
    required String language,
  }) async {
    for (var i = 1; i < verses.length; i++) {
      if (token != _generation) return;
      try {
        final url = await _client.generate(
          apiKey: apiKey,
          text: _prepare(verses[i]),
          voiceId: voiceId,
          language: language,
        );
        if (token != _generation) return;
        await _player.addAudioSource(AudioSource.uri(url));
      } on Object catch (e) {
        // One bad verse should not end the chapter.
        debugPrint('[AudioService] verse $i failed: $e');
      }
    }
  }

  /// Ethiopic full stop so the voice lands the cadence instead of running on.
  String _prepare(String verse) {
    final text = verse.trim();
    if (text.endsWith('።') || text.endsWith('.')) return text;
    return '$text ።';
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> stop() async {
    // Supersede any in-flight generation before touching the player, so it
    // cannot resurrect playback after the user stopped it.
    _generation++;
    await _player.stop();
    stateNotifier.value = AudioState.stopped;
    currentTitleNotifier.value = null;
    currentVerseIndexNotifier.value = null;
  }
}
