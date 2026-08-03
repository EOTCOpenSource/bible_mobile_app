import 'dart:convert';

import 'package:bibleflutter/core/audio/addis_tts_client.dart';
import 'package:bibleflutter/core/audio/addis_voice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AddisVoice.fromJson', () {
    test('reads the documented catalog shape', () {
      final voice = AddisVoice.fromJson({
        'id': 'am-hamen',
        'name': 'Hamen',
        'descriptor': 'Warm conversational delivery',
        'language': 'am',
        'gender': 'female',
        'style': 'Conversational',
        'tags': ['warm', 'friendly'],
        'preview_url': 'https://cdn.example/am-hamen.mp3',
        'is_default': true,
        'isAvailable': true,
      });

      expect(voice.id, 'am-hamen');
      expect(voice.name, 'Hamen');
      expect(voice.descriptor, 'Warm conversational delivery');
      expect(voice.gender, 'female');
      expect(voice.isFemale, isTrue);
      expect(voice.isMale, isFalse);
      expect(voice.style, 'Conversational');
      expect(voice.tags, ['warm', 'friendly']);
      expect(voice.previewUrl, 'https://cdn.example/am-hamen.mp3');
      expect(voice.isDefault, isTrue);
      expect(voice.isAvailable, isTrue);
    });

    test('accepts camelCase keys for the same fields', () {
      final voice = AddisVoice.fromJson({
        'voiceId': 'am-tesfa',
        'displayName': 'Tesfa',
        'previewUrl': 'https://cdn.example/am-tesfa.mp3',
        'isDefault': false,
        'isAvailable': false,
      });

      expect(voice.id, 'am-tesfa');
      expect(voice.name, 'Tesfa');
      expect(voice.previewUrl, 'https://cdn.example/am-tesfa.mp3');
      expect(voice.isAvailable, isFalse);
    });

    test('treats a missing availability flag as available', () {
      // A catalog that stops sending the flag must not empty the picker.
      final voice = AddisVoice.fromJson({'id': 'am-roba', 'name': 'Roba'});
      expect(voice.isAvailable, isTrue);
      expect(voice.previewUrl, isNull);
      expect(voice.tags, isEmpty);
    });
  });

  group('AddisTtsClient.listVoices', () {
    test('sends the key and language, and drops unavailable voices', () async {
      late http.Request seen;

      final client = AddisTtsClient(
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'am-hamen', 'name': 'Hamen', 'is_available': true},
                {'id': 'am-retired', 'name': 'Retired', 'is_available': false},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final voices = await client.listVoices(apiKey: 'sk_test', language: 'am');

      expect(seen.method, 'GET');
      expect(seen.url.path, endsWith('/api/v1/voice/voices'));
      expect(seen.url.queryParameters['language'], 'am');
      expect(seen.headers['x-api-key'], 'sk_test');

      expect(voices.map((v) => v.id), ['am-hamen']);
    });

    test('accepts the list under a `voices` envelope', () async {
      final client = AddisTtsClient(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'voices': [
                  {'id': 'am-muaz', 'name': 'Muaz'},
                ],
              }),
              200,
            )),
      );

      final voices = await client.listVoices(apiKey: 'sk_test');
      expect(voices.single.id, 'am-muaz');
    });

    test('a rejected key surfaces as an auth failure', () async {
      final client = AddisTtsClient(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({'message': 'Invalid API key'}),
              401,
            )),
      );

      await expectLater(
        client.listVoices(apiKey: 'bad'),
        throwsA(
          isA<AddisTtsException>()
              .having((e) => e.isAuthFailure, 'isAuthFailure', isTrue)
              .having((e) => e.message, 'message', 'Invalid API key'),
        ),
      );
    });
  });

  group('AddisTtsClient.generate', () {
    test('posts voice_id and returns the signed audio URL', () async {
      late http.Request seen;

      final client = AddisTtsClient(
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response(
            jsonEncode({
              'id': 'clip_1',
              'audio_url': 'https://cdn.example/clip_1.mp3?sig=abc',
              'usage': {'seconds': 4.2},
            }),
            200,
          );
        }),
      );

      final url = await client.generate(
        apiKey: 'sk_test',
        text: 'ሰላም',
        voiceId: 'am-hamen',
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, endsWith('/api/v1/voice/generations'));

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['voice_id'], 'am-hamen');
      expect(body['text'], 'ሰላም');
      expect(body['language'], 'am');
      expect(body['output_format'], 'mp3_44100');
      // The live endpoint rejects a body without one even though the docs call
      // it optional, so it is always sent.
      expect(body['client_request_id'], isA<String>());
      expect(body['client_request_id'], isNotEmpty);

      expect(url.toString(), 'https://cdn.example/clip_1.mp3?sig=abc');
    });

    test('every generation carries its own request id', () async {
      final ids = <String>[];

      final client = AddisTtsClient(
        httpClient: MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          ids.add(body['client_request_id'] as String);
          return http.Response(
            jsonEncode({'audio_url': 'https://cdn.example/clip.mp3'}),
            200,
          );
        }),
      );

      // A chapter generates verse after verse; ids that repeat would let the
      // API serve one verse's audio for the next one.
      for (var i = 0; i < 25; i++) {
        await client.generate(
          apiKey: 'sk_test',
          text: 'ቁጥር $i',
          voiceId: 'am-hamen',
        );
      }

      expect(ids.toSet(), hasLength(25));
    });

    test('an explicit request id is kept, so a retry can replay it', () async {
      late http.Request seen;

      final client = AddisTtsClient(
        httpClient: MockClient((req) async {
          seen = req;
          return http.Response(
            jsonEncode({'audio_url': 'https://cdn.example/clip.mp3'}),
            200,
          );
        }),
      );

      await client.generate(
        apiKey: 'sk_test',
        text: 'ሰላም',
        voiceId: 'am-hamen',
        clientRequestId: 'retry-me',
      );

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['client_request_id'], 'retry-me');
    });

    test('finds the audio URL nested under an envelope', () async {
      final client = AddisTtsClient(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'data': {'audioUrl': 'https://cdn.example/nested.mp3'},
              }),
              200,
            )),
      );

      final url = await client.generate(
        apiKey: 'sk_test',
        text: 'ሰላም',
        voiceId: 'am-hamen',
      );
      expect(url.toString(), 'https://cdn.example/nested.mp3');
    });

    test('a response with no audio URL is an error, not a silent no-op',
        () async {
      final client = AddisTtsClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode({'id': 'clip_1'}), 200),
        ),
      );

      await expectLater(
        client.generate(apiKey: 'sk_test', text: 'ሰላም', voiceId: 'am-hamen'),
        throwsA(isA<AddisTtsException>()),
      );
    });
  });
}
