/// One entry from the Addis AI voice catalog
/// (`GET /api/v1/voice/voices?language=am`).
///
/// The catalog is served, not compiled in: Addis AI adds and retires voices,
/// so voices are always fetched and only [isAvailable] ones are offered. The
/// only thing persisted is the chosen [id].
class AddisVoice {
  const AddisVoice({
    required this.id,
    required this.name,
    this.descriptor = '',
    this.language = 'am',
    this.gender = '',
    this.style = '',
    this.tags = const [],
    this.previewUrl,
    this.isDefault = false,
    this.isAvailable = true,
  });

  /// Voice id sent as `voice_id` on generation, e.g. `am-hamen`.
  final String id;

  /// Display name, e.g. `Hamen`.
  final String name;

  /// Short blurb, e.g. "Warm conversational delivery".
  final String descriptor;

  /// `am` (Amharic) or `om` (Afaan Oromo).
  final String language;

  /// `male` or `female`. Empty when the catalog omits it.
  final String gender;

  /// Use case, e.g. `Conversational`, `Narration`, `Commercial`.
  final String style;

  final List<String> tags;

  /// Sample clip for the preview button. Null when the catalog omits it.
  final String? previewUrl;

  /// The catalog's own suggested default for the language.
  final bool isDefault;

  /// Retired or temporarily offline voices come back with this false. Never
  /// offer them — generation will fail.
  final bool isAvailable;

  bool get isMale => gender.toLowerCase() == 'male';
  bool get isFemale => gender.toLowerCase() == 'female';

  /// The API mixes snake_case (request fields) and camelCase (`isAvailable`),
  /// and the catalog is documented as evolving, so every key is read
  /// leniently and every field except [id] has a fallback.
  factory AddisVoice.fromJson(Map<String, dynamic> json) {
    return AddisVoice(
      id: _str(json, ['id', 'voice_id', 'voiceId']),
      name: _str(json, ['name', 'display_name', 'displayName']),
      descriptor: _str(json, ['descriptor', 'description', 'summary']),
      language: _str(json, ['language', 'lang', 'language_code'], 'am'),
      gender: _str(json, ['gender', 'sex']),
      style: _str(json, ['style', 'use_case', 'useCase', 'category']),
      tags: _stringList(json, ['tags', 'labels']),
      previewUrl: _nullableStr(json, [
        'preview_url',
        'previewUrl',
        'preview',
        'sample_url',
        'sampleUrl',
      ]),
      isDefault: _bool(json, ['is_default', 'isDefault', 'default']),
      // Absent means available: a catalog that stops sending the flag should
      // not silently empty the picker.
      isAvailable: _bool(json, ['is_available', 'isAvailable', 'available'],
          fallback: true),
    );
  }

  static String _str(Map<String, dynamic> j, List<String> keys,
      [String fallback = '']) {
    return _nullableStr(j, keys) ?? fallback;
  }

  static String? _nullableStr(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static bool _bool(Map<String, dynamic> j, List<String> keys,
      {bool fallback = false}) {
    for (final k in keys) {
      final v = j[k];
      if (v is bool) return v;
      if (v is String) {
        if (v.toLowerCase() == 'true') return true;
        if (v.toLowerCase() == 'false') return false;
      }
    }
    return fallback;
  }

  static List<String> _stringList(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is List) {
        return v.whereType<String>().toList(growable: false);
      }
    }
    return const [];
  }

  @override
  bool operator ==(Object other) => other is AddisVoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
