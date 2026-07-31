import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'addis_tts_client.dart';
import 'addis_voice.dart';
import 'tts_settings_store.dart';

final ttsSettingsStoreProvider = Provider<TtsSettingsStore>(
  (_) => const TtsSettingsStore(),
);

final addisTtsClientProvider = Provider<AddisTtsClient>((ref) {
  final client = AddisTtsClient();
  ref.onDispose(client.close);
  return client;
});

/// The user's own API key, or null when they have not set one up yet.
///
/// Invalidate after saving or clearing a key so the voice list and the audio
/// controls re-resolve.
final addisApiKeyProvider = FutureProvider<String?>((ref) async {
  return ref.watch(ttsSettingsStoreProvider).readApiKey();
});

/// The chosen `voice_id`, or null to mean "use the catalog default".
final selectedVoiceIdProvider = FutureProvider<String?>((ref) async {
  return ref.watch(ttsSettingsStoreProvider).readVoiceId();
});

/// The live voice catalog for the reading language.
///
/// Errors here are meaningful to the UI: an [AddisTtsException] with
/// [AddisTtsException.isAuthFailure] means the saved key is bad, which the
/// settings page turns into "check your key" rather than a generic failure.
final voiceCatalogProvider =
    FutureProvider.family<List<AddisVoice>, String>((ref, language) async {
  final apiKey = await ref.watch(addisApiKeyProvider.future);
  if (apiKey == null) return const [];

  final voices = await ref
      .watch(addisTtsClientProvider)
      .listVoices(apiKey: apiKey, language: language);

  // Surface the catalog's own default first, then keep server order.
  final sorted = [...voices];
  sorted.sort((a, b) {
    if (a.isDefault == b.isDefault) return 0;
    return a.isDefault ? -1 : 1;
  });
  return sorted;
});

/// The voice that will actually be used: the user's pick when it is still in
/// the catalog, otherwise the catalog default, otherwise the first available.
///
/// Resolving here rather than at the call site means a voice that Addis AI
/// retires degrades to a working default instead of failing every generation.
final effectiveVoiceProvider =
    FutureProvider.family<AddisVoice?, String>((ref, language) async {
  final voices = await ref.watch(voiceCatalogProvider(language).future);
  if (voices.isEmpty) return null;

  final chosenId = await ref.watch(selectedVoiceIdProvider.future);
  if (chosenId != null) {
    for (final v in voices) {
      if (v.id == chosenId) return v;
    }
  }
  for (final v in voices) {
    if (v.isDefault) return v;
  }
  return voices.first;
});
