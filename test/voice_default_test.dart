import 'dart:convert';

import 'package:bibleflutter/core/audio/addis_tts_client.dart';
import 'package:bibleflutter/core/audio/tts_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Hamen is flagged as the *catalog's* default here on purpose: the app reads
/// in Yohannes, and that has to win over the catalog's own suggestion.
const _kCatalog = [
  {'id': 'am-hamen', 'name': 'Hamen', 'gender': 'female', 'is_default': true},
  {'id': 'am-yohanes-calm', 'name': 'Yohannes', 'gender': 'male'},
  {'id': 'am-tesfa', 'name': 'Tesfa', 'gender': 'male'},
];

ProviderContainer _container({
  List<Map<String, dynamic>> catalog = _kCatalog,
  String? savedVoiceId,
}) {
  final client = AddisTtsClient(
    httpClient: MockClient(
      (_) async => http.Response(jsonEncode({'data': catalog}), 200),
    ),
  );

  return ProviderContainer(
    overrides: [
      addisTtsClientProvider.overrideWithValue(client),
      addisApiKeyProvider.overrideWith((_) async => 'sk_test'),
      selectedVoiceIdProvider.overrideWith((_) async => savedVoiceId),
    ],
  );
}

void main() {
  group('the voice a fresh setup reads in', () {
    test('is Yohannes, over the catalog default', () async {
      final container = _container();
      addTearDown(container.dispose);

      final voice = await container.read(effectiveVoiceProvider('am').future);
      expect(voice?.id, 'am-yohanes-calm');
    });

    test('is listed first, so the list agrees with what is in effect',
        () async {
      final container = _container();
      addTearDown(container.dispose);

      final voices = await container.read(voiceCatalogProvider('am').future);
      expect(voices.first.id, 'am-yohanes-calm');
      // The catalog's own default keeps its place ahead of the remainder.
      expect(voices[1].id, 'am-hamen');
    });

    test('gives way to a voice the user chose', () async {
      final container = _container(savedVoiceId: 'am-tesfa');
      addTearDown(container.dispose);

      final voice = await container.read(effectiveVoiceProvider('am').future);
      expect(voice?.id, 'am-tesfa');
    });

    test('is found by name when the id has changed', () async {
      final container = _container(catalog: const [
        {'id': 'am-hamen', 'name': 'Hamen', 'is_default': true},
        {'id': 'am-yohanes-v2', 'name': 'Yohannes'},
      ]);
      addTearDown(container.dispose);

      final voice = await container.read(effectiveVoiceProvider('am').future);
      expect(voice?.id, 'am-yohanes-v2');
    });

    test('falls back to the catalog default once Yohannes is retired',
        () async {
      final container = _container(catalog: const [
        {'id': 'am-tesfa', 'name': 'Tesfa'},
        {'id': 'am-hamen', 'name': 'Hamen', 'is_default': true},
      ]);
      addTearDown(container.dispose);

      final voice = await container.read(effectiveVoiceProvider('am').future);
      expect(voice?.id, 'am-hamen');
    });

    test('falls back to a saved pick that no longer exists being ignored',
        () async {
      final container = _container(savedVoiceId: 'am-retired');
      addTearDown(container.dispose);

      final voice = await container.read(effectiveVoiceProvider('am').future);
      expect(voice?.id, 'am-yohanes-calm');
    });
  });
}
