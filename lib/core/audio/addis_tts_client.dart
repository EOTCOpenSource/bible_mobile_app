import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'addis_voice.dart';

/// Where to get an API key. Shown on the voice settings page — users bring
/// their own key, so this link is part of the setup flow, not just docs.
const kAddisAiSignupUrl = 'https://addisassistant.com/';

/// Thrown for any non-2xx response. [isAuthFailure] is what the UI keys on to
/// send the user back to the key field instead of showing a generic error.
class AddisTtsException implements Exception {
  const AddisTtsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isAuthFailure => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'AddisTtsException($statusCode): $message';
}

/// Thin client over the Addis AI voice API.
///
/// Endpoints per https://docs.addisassistant.com/docs/capabilities/text-to-speech:
///   GET  /api/v1/voice/voices?language=am   → catalog
///   POST /api/v1/voice/generations          → { id, audio_url, usage }
///
/// Generation returns a *signed URL*, not inline audio, so callers stream from
/// [Uri] rather than decoding bytes.
class AddisTtsClient {
  AddisTtsClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _kDefaultBaseUrl;

  static const _kDefaultBaseUrl = 'https://api.addisassistant.com/api/v1';

  final http.Client _http;
  final String _baseUrl;

  Map<String, String> _headers(String apiKey) => {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      };

  /// The voice catalog for [language], newest state each call.
  ///
  /// Unavailable voices are filtered out here so no caller has to remember to:
  /// offering one would just produce a failed generation later.
  Future<List<AddisVoice>> listVoices({
    required String apiKey,
    String language = 'am',
    String? gender,
  }) async {
    final uri = Uri.parse('$_baseUrl/voice/voices').replace(
      queryParameters: {
        'language': language,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      },
    );

    final res = await _http.get(uri, headers: _headers(apiKey));
    final body = _decode(res, 'Could not load the voice list');

    final raw = _extractList(body);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AddisVoice.fromJson)
        .where((v) => v.id.isNotEmpty && v.isAvailable)
        .toList(growable: false);
  }

  /// Generates [text] with [voiceId] and returns the signed audio URL.
  ///
  /// [clientRequestId] is the API's idempotency key. The docs call it optional
  /// but the live endpoint rejects a body without one, so a unique id is
  /// always sent; pass your own only to deliberately replay a request.
  Future<Uri> generate({
    required String apiKey,
    required String text,
    required String voiceId,
    String language = 'am',
    String outputFormat = 'mp3_44100',
    String? clientRequestId,
  }) async {
    final res = await _http.post(
      Uri.parse('$_baseUrl/voice/generations'),
      headers: _headers(apiKey),
      body: jsonEncode({
        'text': text,
        'voice_id': voiceId,
        'language': language,
        'output_format': outputFormat,
        'client_request_id': clientRequestId ?? _newClientRequestId(),
      }),
    );

    final body = _decode(res, 'Audio generation failed');
    final url = _extractAudioUrl(body);
    if (url == null) {
      throw const AddisTtsException(
        'The generation response contained no audio URL.',
      );
    }
    return Uri.parse(url);
  }

  void close() => _http.close();

  /// A fresh idempotency key.
  ///
  /// A chapter fires one generation per verse in quick succession, so the
  /// timestamp alone can repeat within the same microsecond tick — the counter
  /// and the random suffix are what actually keep verses from deduplicating
  /// into each other's audio.
  String _newClientRequestId() {
    final n = ++_requestCounter;
    final noise = _random.nextInt(1 << 32).toRadixString(16);
    return 'bibleflutter-${DateTime.now().microsecondsSinceEpoch}-$n-$noise';
  }

  static int _requestCounter = 0;
  static final Random _random = Random();

  // ── response handling ─────────────────────────────────────────────────────

  Map<String, dynamic> _decode(http.Response res, String failureLabel) {
    Map<String, dynamic>? body;
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
        if (decoded is List) body = {'data': decoded};
      } on FormatException {
        // Fall through — handled as a non-JSON error below.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body ?? const {};
    }

    throw AddisTtsException(
      _errorMessage(body) ?? '$failureLabel (HTTP ${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  String? _errorMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    for (final key in ['message', 'error', 'detail']) {
      final v = body[key];
      if (v is String && v.isNotEmpty) return v;
      if (v is Map && v['message'] is String) return v['message'] as String;
    }
    return null;
  }

  /// Accepts a bare array or the list nested under a common envelope key.
  List<dynamic> _extractList(Map<String, dynamic> body) {
    for (final key in ['data', 'voices', 'results', 'items']) {
      final v = body[key];
      if (v is List) return v;
    }
    return const [];
  }

  String? _extractAudioUrl(Map<String, dynamic> body) {
    const keys = ['audio_url', 'audioUrl', 'url', 'signed_url', 'signedUrl'];
    for (final k in keys) {
      final v = body[k];
      if (v is String && v.isNotEmpty) return v;
    }
    // Same fields one level down, under `data` / `clip` / `generation`.
    for (final wrapper in ['data', 'clip', 'generation', 'result']) {
      final nested = body[wrapper];
      if (nested is Map<String, dynamic>) {
        for (final k in keys) {
          final v = nested[k];
          if (v is String && v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }
}
