import 'package:flutter/material.dart';
import '../annotations/annotation_models.dart';
import '../api/api_client.dart';

class SyncRepository {
  const SyncRepository(this._client, this._token);

  final ApiClient _client;
  final String _token;

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<String> createBookmark(Bookmark b) async {
    final res = await _client.post(
      '/bookmarks',
      body: {
        'book': b.bookId,
        'bookId': b.bookId,
        'chapter': b.chapter,
        'verseStart': b.verseStart,
        'verseCount': b.verseCount,
      },
      token: _token,
    );
    return _remoteId(res, 'bookmark');
  }

  Future<void> updateBookmark(String remoteId, Bookmark b) => _client.put(
        '/bookmarks/$remoteId',
        body: {
          'book': b.bookId,
          'bookId': b.bookId,
          'chapter': b.chapter,
          'verseStart': b.verseStart,
          'verseCount': b.verseCount,
        },
        token: _token,
      );

  Future<void> deleteBookmark(String remoteId) =>
      _client.delete('/bookmarks/$remoteId', token: _token);

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<String> createNote(Note n) async {
    final res = await _client.post(
      '/notes',
      body: {
        'bookId': n.bookId,
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
          'content': n.content,
          'visibility': n.isPrivate ? 'private' : 'public',
        },
        token: _token,
      );

  Future<void> deleteNote(String remoteId) =>
      _client.delete('/notes/$remoteId', token: _token);

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<String> createHighlight(Highlight h) async {
    final res = await _client.post(
      '/highlights',
      body: {
        'book': h.bookId,
        'bookId': h.bookId,
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
        body: {'bookId': bookId, 'chapter': chapter},
        token: _token,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _remoteId(Map<String, dynamic> res, String key) {
    final data = res['data'];
    if (data is Map) {
      final obj = data[key];
      if (obj is Map && obj['_id'] is String) return obj['_id'] as String;
      if (data['_id'] is String) return data['_id'] as String;
    }
    throw Exception('Cannot parse remote id for $key');
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

  // ── Fetch (pull from server) ────────────────────────────────────────────────

  Future<List<Bookmark>> fetchBookmarks() async {
    final res = await _client.get('/bookmarks', token: _token);
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      final bookId = (m['book'] ?? m['bookId'] ?? '') as String;
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
    }).toList();
  }

  Future<List<Highlight>> fetchHighlights() async {
    final res = await _client.get('/highlights', token: _token);
    final data = res['data'];
    final list = (data is Map ? data['data'] : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      final bookId = (m['book'] ?? m['bookId'] ?? '') as String;
      final colorName = (m['color'] as String?) ?? 'yellow';
      return Highlight(
        bookId: bookId,
        bookNumber: 0,
        chapter: (m['chapter'] as num).toInt(),
        verseStart: (m['verseStart'] as num).toInt(),
        verseCount: (m['verseCount'] as num?)?.toInt() ?? 1,
        color: _colorFromName(colorName),
        note: m['note'] as String?,
        createdAt: _parseDate(m['createdAt']) ?? now,
        updatedAt: _parseDate(m['updatedAt']) ?? now,
        syncStatus: SyncStatus.synced,
        remoteId: m['_id'] as String?,
      );
    }).toList();
  }

  Future<List<Note>> fetchNotes() async {
    final res = await _client.get('/notes', token: _token);
    final data = res['data'];
    final list = (data is Map ? data['notes'] : data) as List? ?? [];
    final now = DateTime.now();
    return list.whereType<Map<String, dynamic>>().map((m) {
      final bookId = (m['bookId'] ?? m['book'] ?? '') as String;
      return Note(
        bookId: bookId,
        bookNumber: 0,
        chapter: (m['chapter'] as num).toInt(),
        verseStart: (m['verseStart'] as num).toInt(),
        verseCount: (m['verseCount'] as num?)?.toInt() ?? 1,
        content: (m['content'] as String?) ?? '',
        isPrivate: (m['visibility'] as String?) != 'public',
        createdAt: _parseDate(m['createdAt']) ?? now,
        updatedAt: _parseDate(m['updatedAt']) ?? now,
        syncStatus: SyncStatus.synced,
        remoteId: m['_id'] as String?,
      );
    }).where((n) => n.content.isNotEmpty).toList();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }
}
