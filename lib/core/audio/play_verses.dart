import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/me/presentation/pages/voice_settings_page.dart';
import '../l10n/l10n.dart';
import 'audio_service.dart';
import 'tts_providers.dart';

/// Reads [verses] aloud with the user's own key and chosen voice, and turns
/// every way that can fail into something the user can act on.
///
/// Both entry points into audio — the reader toolbar and the daily verse card —
/// go through here. A missing or rejected key is the common case on a fresh
/// install and is fixable on the voice settings page, so it routes there rather
/// than leaving a button that appears to do nothing.
///
/// [title] doubles as the identity of what is playing: callers compare it
/// against [AudioService.currentTitleNotifier] to know whether *their* audio is
/// the one running.
Future<void> playVersesAloud({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required List<String> verses,
  String language = 'am',
}) async {
  final s = L10n.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final apiKey = await ref.read(addisApiKeyProvider.future);
  final voice = await ref.read(effectiveVoiceProvider(language).future);
  if (!context.mounted) return;

  final result = await AudioService.instance.startChapter(
    title: title,
    verses: verses,
    apiKey: apiKey,
    voiceId: voice?.id,
    language: language,
  );
  if (!context.mounted) return;

  void openVoiceSettings() {
    navigator.push(
      MaterialPageRoute(builder: (_) => const VoiceSettingsPage()),
    );
  }

  switch (result) {
    case StartAudioResult.started:
    case StartAudioResult.cancelled:
      break;
    case StartAudioResult.missingApiKey:
      messenger.showSnackBar(SnackBar(content: Text(s.voiceKeyRequired)));
      openVoiceSettings();
    case StartAudioResult.invalidApiKey:
      messenger.showSnackBar(SnackBar(content: Text(s.voiceKeyRejected)));
      openVoiceSettings();
    case StartAudioResult.noVoiceAvailable:
      messenger.showSnackBar(SnackBar(content: Text(s.voiceListEmpty)));
      openVoiceSettings();
    case StartAudioResult.failed:
      messenger.showSnackBar(
        SnackBar(
          content: Text(AudioService.instance.lastError ?? s.voiceLoadFailed),
        ),
      );
  }
}
