import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the two things audio reading needs from the user: their own Addis
/// AI API key and the voice they picked.
///
/// The key goes to secure storage (same place as the auth token — it is a
/// credential the user pays against). The voice id is a plain preference.
class TtsSettingsStore {
  const TtsSettingsStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  static const _apiKeyKey = 'addis_ai_api_key';
  static const _voiceIdKey = 'addis_ai_voice_id';

  Future<String?> readApiKey() async {
    final key = await _secure.read(key: _apiKeyKey);
    if (key == null) return null;
    final trimmed = key.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> saveApiKey(String key) =>
      _secure.write(key: _apiKeyKey, value: key.trim());

  /// Clears the key. The chosen voice is deliberately kept — a user
  /// re-entering a key should not have to pick their voice again.
  Future<void> clearApiKey() => _secure.delete(key: _apiKeyKey);

  Future<bool> hasApiKey() async => (await readApiKey()) != null;

  /// The chosen `voice_id`, or null to fall back to the catalog default.
  Future<String?> readVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_voiceIdKey);
    return (id == null || id.isEmpty) ? null : id;
  }

  Future<void> saveVoiceId(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceIdKey, voiceId);
  }
}
