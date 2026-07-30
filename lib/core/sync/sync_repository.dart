import 'package:flutter/material.dart';
import '../annotations/annotation_models.dart';
import '../api/api_client.dart';
import '../../features/books/data/models/book_identity.dart';

class SyncRepository {
  const SyncRepository(this._client, this._token);

  final ApiClient _client;
  final String _token;

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<String> createBookmark(Bookmark b) async {
    final apiId = _toApiBookId(b.bookId);
    final res = await _client.post(
      '/bookmarks',
      body: {
        'book': apiId,
        'bookId': apiId,
        'chapter': b.chapter,
        'verseStart': b.verseStart,
        'verseCount': b.verseCount,
      },
      token: _token,
    );
    return _remoteId(res, 'bookmark');
  }

  Future<void> updateBookmark(String remoteId, Bookmark b) {
    final apiId = _toApiBookId(b.bookId);
    return _client.put(
      '/bookmarks/$remoteId',
      body: {
        'book': apiId,
        'bookId': apiId,
        'chapter': b.chapter,
        'verseStart': b.verseStart,
        'verseCount': b.verseCount,
      },
      token: _token,
    );
  }

  Future<void> deleteBookmark(String remoteId) =>
      _client.delete('/bookmarks/$remoteId', token: _token);

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<String> createNote(Note n) async {
    final res = await _client.post(
      '/notes',
      body: {
        'bookId': _toApiBookId(n.bookId),
        'chapter': n.chapter,
        'verseStart': n.verseStart,
        'verseCount': n.verseCount,
        'content': n.content,
        'visibility': n.isPrivate ? 'private' : 'public',
      },
      token: _token,
    );
    return _remoteId(res, 'note');
  }

  Future<void> updateNote(String remoteId, Note n) => _client.put(
        '/notes/$remoteId',
        body: {
          'bookId': _toApiBookId(n.bookId),
          'chapter': n.chapter,
          'verseStart': n.verseStart,
          'verseCount': n.verseCount,
          'content': n.content,
          'visibility': n.isPrivate ? 'private' : 'public',
        },
        token: _token,
      );

  Future<void> deleteNote(String remoteId) =>
      _client.delete('/notes/$remoteId', token: _token);

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<String> createHighlight(Highlight h) async {
    final apiId = _toApiBookId(h.bookId);
    final res = await _client.post(
      '/highlights',
      body: {
        'book': apiId,
        'bookId': apiId,
        'chapter': h.chapter,
        'verseStart': h.verseStart,
        'verseCount': h.verseCount,
        'color': _colorName(h.color),
        if (h.note != null) 'note': h.note,
      },
      token: _token,
    );
    return _remoteId(res, 'highlight');
  }

  Future<void> updateHighlight(String remoteId, Highlight h) => _client.put(
        '/highlights/$remoteId',
        body: {
          'color': _colorName(h.color),
          if (h.note != null) 'note': h.note,
        },
        token: _token,
      );

  Future<void> deleteHighlight(String remoteId) =>
      _client.delete('/highlights/$remoteId', token: _token);

  // ── Progress ───────────────────────────────────────────────────────────────

  Future<void> logReadingProgress({
    required String bookId,
    required int chapter,
  }) =>
      _client.post(
        '/progress/log-reading',
        body: {'bookId': _toApiBookId(bookId), 'chapter': chapter},
        token: _token,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _remoteId(Map<String, dynamic> res, String key) {
    final data = res['data'];
    if (data is Map) {
      final obj = data[key];
      if (obj is Map && obj['_id'] is String) return obj['_id'] as String;
      if (data['_id'] is String) return data['_id'] as String;
      // Some endpoints wrap inside data.data
      final inner = data['data'];
      if (inner is Map && inner['_id'] is String) return inner['_id'] as String;
    }
    throw Exception('Cannot parse remote id for $key: ${res['data']}');
  }

  // Maps local ARGB palette to the backend's accepted color names.
  static const _colorNames = <int, String>{
    0xFFFFE062: 'yellow',
    0xFF3BAD49: 'green',
    0xFFFF4B26: 'pink',
    0xFF5778C5: 'blue',
    0xFFB61F21: 'red',
    0xFF704A6A: 'purple',
  };

  static const _nameToColor = <String, Color>{
    'yellow': Color(0xFFFFE062),
    'green':  Color(0xFF3BAD49),
    'pink':   Color(0xFFFF4B26),
    'blue':   Color(0xFF5778C5),
    'red':    Color(0xFFB61F21),
    'purple': Color(0xFF704A6A),
  };

  static String _colorName(Color color) =>
      _colorNames[color.toARGB32()] ?? 'yellow';

  static Color _colorFromName(String name) =>
      _nameToColor[name] ?? const Color(0xFFFFE062);

  // Legacy reverse lookup, kept only so rows written by older builds still
  // resolve. The live translation is [_normalizeBookId] → USFM.
  //
  // ignore: unused_field
  static const _bookIdToName = <String, String>{
    'genesis': 'Genesis', 'exodus': 'Exodus', 'leviticus': 'Leviticus',
    'numbers': 'Numbers', 'deuteronomy': 'Deuteronomy', 'joshua': 'Joshua',
    'judges': 'Judges', 'ruth': 'Ruth', '1-samuel': '1 Samuel',
    '2-samuel': '2 Samuel', '1-kings': '1 Kings', '2-kings': '2 Kings',
    '1-chronicles': '1 Chronicles', '2-chronicles': '2 Chronicles',
    'jubilees': 'Jubilees', 'enoch': 'Enoch', 'ezra': 'Ezra',
    'nehemiah': 'Nehemiah', '3-book-of-ezra': '3 Book of Ezra',
    '2nd-book-of-ezra': '2nd Book of Ezra', 'book-of-tobit': 'Book of Tobit',
    'book-of-judith': 'Book of Judith', 'esther': 'Esther',
    '1-maccabees': '1 Maccabees', '2-maccabees': '2 Maccabees',
    '3-maccabees': '3 Maccabees', 'job': 'Job', 'psalms': 'Psalms',
    'proverbs': 'Proverbs', 'book-of-admonition': 'Book of Admonition',
    'wisdom-of-solomon': 'Wisdom of Solomon', 'ecclesiastes': 'Ecclesiastes',
    'song-of-solomon': 'Song of Solomon', 'book-of-sirach': 'book of sirach',
    'isaiah': 'Isaiah', 'jeremiah': 'Jeremiah', 'baruch': 'Baruch',
    'lamentations': 'Lamentations',
    'thr-letter-of-jeremiah': 'Thr letter of Jeremiah',
    'teref-baruch': 'Teref Baruch', 'ezekiel': 'Ezekiel', 'daniel': 'Daniel',
    'hosea': 'Hosea', 'amos': 'Amos', 'micah': 'Micah', 'joel': 'Joel',
    'obadiah': 'Obadiah', 'jonah': 'Jonah', 'nahum': 'Nahum',
    'habakkuk': 'Habakkuk', 'zephaniah': 'Zephaniah', 'haggai': 'Haggai',
    'zechariah': 'Zechariah', 'malachi': 'Malachi', 'matthew': 'Matthew',
    'mark': 'Mark', 'luke': 'Luke', 'john': 'John', 'acts': 'Acts',
    'romans': 'Romans', '1-corinthians': '1 Corinthians',
    '2-corinthians': '2 Corinthians', 'galatians': 'Galatians',
    'ephesians': 'Ephesians', 'philippians': 'Philippians',
    'colossians': 'Colossians', '1-thessalonians': '1 Thessalonians',
    '2-thessalonians': '2 Thessalonians', '1-timothy': '1 Timothy',
    '2-timothy': '2 Timothy', 'titus': 'Titus', 'philemon': 'Philemon',
    'hebrews': 'Hebrews', '1-peter': '1 Peter', '2-peter': '2 Peter',
    '1-john': '1 John', '2-john': '2 John', '3-john': '3 John',
    'james': 'James', 'jude': 'Jude', 'revelation': 'Revelation',
  };

  /// Anything the server sends → the USFM id every local table now uses.
  ///
  /// Accepts the web frontend's kebab-case ("1-samuel"), the title-case form
  /// older mobile builds pushed ("1 Samuel"), and a USFM id that is already
  /// correct, so a mixed-vintage account converges instead of duplicating.
  static String _normalizeBookId(String raw) =>
      raw.isEmpty ? raw : usfmFromAnyBookId(raw);

  /// USFM id → the kebab-case id the API and web frontend expect.
  ///
  /// The wire format is frozen at kebab-case of the *legacy* English name
  /// ("book-of-tobit", "thr-letter-of-jeremiah"), which is what the web app
  /// already has stored. Switching the server to USFM would orphan every
  /// annotation it has written, so the translation lives here instead.
  static String _toApiBookId(String usfmId) => apiBookIdFromUsfm(usfmId);

  // ── Fetch (pull from server) ────────────────────────────────────────────────

  Future<List<Bookmark>> fetchBookmarks() async {
    final res = await _client.get('/bookmarks', token: _token);
    final data = res['data'];
    final list = (data is Map ? (data['data'] ?? data) : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      final raw = (m['book'] ?? m['bookId'] ?? '') as String;
      final bookId = _normalizeBookId(raw);
      return Bookmark(
        bookId: bookId,
        bookNumber: 0,
        chapter: (m['chapter'] as num).toInt(),
        verseStart: (m['verseStart'] as num).toInt(),
        verseCount: (m['verseCount'] as num?)?.toInt() ?? 1,
        createdAt: _parseDate(m['createdAt']) ?? now,
        updatedAt: _parseDate(m['updatedAt']) ?? now,
        syncStatus: SyncStatus.synced,
        remoteId: m['_id'] as String?,
      );
    }).where((b) => b.bookId.isNotEmpty).toList();
  }

  Future<List<Highlight>> fetchHighlights() async {
    final res = await _client.get('/highlights', token: _token);
    final data = res['data'];
    final list = (data is Map ? (data['data'] ?? data) : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      final verseRef = m['verseRef'] as Map<String, dynamic>?;
      final raw = (verseRef?['book'] ?? m['book'] ?? m['bookId'] ?? '') as String;
      final bookId = _normalizeBookId(raw);
      final chapter = ((verseRef?['chapter'] ?? m['chapter']) as num?)?.toInt() ?? 0;
      final verseStart = ((verseRef?['verseStart'] ?? verseRef?['verse'] ?? m['verseStart']) as num?)?.toInt() ?? 1;
      final verseCount = ((verseRef?['verseCount'] ?? m['verseCount']) as num?)?.toInt() ?? 1;
      final colorName = (m['color'] as String?) ?? 'yellow';
      return Highlight(
        bookId: bookId,
        bookNumber: 0,
        chapter: chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        color: _colorFromName(colorName),
        note: m['note'] as String?,
        createdAt: _parseDate(m['createdAt']) ?? now,
        updatedAt: _parseDate(m['updatedAt']) ?? now,
        syncStatus: SyncStatus.synced,
        remoteId: m['_id'] as String?,
      );
    }).where((h) => h.bookId.isNotEmpty && h.chapter > 0).toList();
  }

  Future<List<Note>> fetchNotes() async {
    final res = await _client.get('/notes', token: _token);
    final data = res['data'];
    final list = (data is Map
        ? (data['notes'] ?? data['data'] ?? data)
        : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      // Handle both flat and nested verseRef structures
      final verseRef = m['verseRef'] as Map<String, dynamic>?;
      final raw = (verseRef?['book'] ?? m['bookId'] ?? m['book'] ?? '') as String;
      final bookId = _normalizeBookId(raw);
      final chapter = ((verseRef?['chapter'] ?? m['chapter']) as num?)?.toInt() ?? 0;
      final verseStart = ((verseRef?['verseStart'] ?? verseRef?['verse'] ?? m['verseStart']) as num?)?.toInt() ?? 1;
      final verseCount = ((verseRef?['verseCount'] ?? m['verseCount']) as num?)?.toInt() ?? 1;
      return Note(
        bookId: bookId,
        bookNumber: 0,
        chapter: chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        content: (m['content'] as String?) ?? '',
        isPrivate: (m['visibility'] as String?) != 'public',
        createdAt: _parseDate(m['createdAt']) ?? now,
        updatedAt: _parseDate(m['updatedAt']) ?? now,
        syncStatus: SyncStatus.synced,
        remoteId: m['_id'] as String?,
      );
    }).where((n) => n.content.isNotEmpty && n.bookId.isNotEmpty && n.chapter > 0).toList();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
