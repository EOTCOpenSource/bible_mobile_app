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

  static const _colorNames = <int, String>{
    0xFFFFEB3B: 'yellow',
    0xFF80CBC4: 'teal',
    0xFF90CAF9: 'blue',
    0xFFEF9A9A: 'red',
    0xFFCE93D8: 'purple',
  };

  static String _colorName(Color color) =>
      _colorNames[color.toARGB32()] ?? 'yellow';
}
