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

  // Surface the voice the app actually reads in first, then the catalog's own
  // default, then keep server order — the list runs to 19 voices, so the one
  // in effect should not be somewhere down it. Bucketed rather than sorted
  // because Dart's sort is not stable, and equal-ranked voices should stay in
  // the order the catalog sent them.
  final preferred = <AddisVoice>[];
  final catalogDefault = <AddisVoice>[];
  final rest = <AddisVoice>[];
  for (final v in voices) {
    if (isPreferredVoice(v)) {
      preferred.add(v);
    } else if (v.isDefault) {
      catalogDefault.add(v);
    } else {
      rest.add(v);
    }
  }
  return [...preferred, ...catalogDefault, ...rest];
});

/// The voice this app reads scripture in until the user picks another —
/// Yohannes, a calm male narration voice.
///
/// A preference, never a requirement: the catalog is documented as changing,
/// so if Addis AI retires this id the resolution below simply moves on to the
/// next fallback instead of leaving the reader silent.
const kPreferredVoiceId = 'am-yohanes-calm';

/// Matches Yohannes by name when the id has moved on, since the catalog is
/// served rather than compiled in.
const _kPreferredVoiceName = 'yohan';

/// Whether [voice] is the app's preferred default, by id or by name.
bool isPreferredVoice(AddisVoice voice) =>
    voice.id == kPreferredVoiceId ||
    voice.name.toLowerCase().contains(_kPreferredVoiceName);

/// The voice that will actually be used: the user's pick when it is still in
/// the catalog, otherwise Yohannes, otherwise the catalog default, otherwise
/// the first available.
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
    if (isPreferredVoice(v)) return v;
  }

  for (final v in voices) {
    if (v.isDefault) return v;
  }
  return voices.first;
});
