import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../features/books/data/models/book.dart';
import '../../features/books/data/models/book_index_entry.dart';
import '../../features/books/data/repositories/bible_repository.dart';
import '../annotations/annotation_models.dart';
import '../storage/app_database.dart';
import 'web_fonts.dart';

/// Every route the Local Web Reader serves.
///
/// Reads scripture through [BibleRepository] rather than off the filesystem —
/// editions are SQLite databases in app-private storage, and the repository
/// already holds the open read-only handle and its caches. Annotation writes go
/// straight into the same [AppDatabase] the Flutter UI uses, so a highlight made
/// in the browser is in the app the next time a chapter is opened, with no
/// restart and no second connection to the file.
///
/// Books are addressed by USFM id (`GEN`, `1ES`), not by number: numbers are a
/// per-edition display order, so `/api/book/1` means different books in
/// different editions while `/api/book/GEN` never does.
class ApiRouter {
  ApiRouter({required this.db, required this.bible});

  final AppDatabase db;
  final BibleRepository bible;

  /// Responses above this many bytes are gzipped. A whole book of Psalms is
  /// megabytes of Ethiopic UTF-8 and compresses to roughly a fifth.
  static const _gzipThreshold = 8 * 1024;

  Handler get handler {
    final router = Router(notFoundHandler: _notFound);

    // ── Bible data ──────────────────────────────────────────────────────────
    router.get('/api/index', _index);
    router.get('/api/fonts', _fonts);
    router.get('/api/book/<id>', _book);
    router.get('/api/book/<id>/<chapter>', _chapter);

    // ── Annotations ─────────────────────────────────────────────────────────
    router.get('/api/bookmarks', _listBookmarks);
    router.post('/api/bookmarks', _createBookmark);
    router.delete('/api/bookmarks/<id>', _deleteBookmark);

    router.get('/api/highlights', _listHighlights);
    router.post('/api/highlights', _createHighlight);
    router.delete('/api/highlights/<id>', _deleteHighlight);

    router.get('/api/notes', _listNotes);
    router.post('/api/notes', _createNote);
    router.patch('/api/notes/<id>', _updateNote);
    router.delete('/api/notes/<id>', _deleteNote);

    // ── Static ──────────────────────────────────────────────────────────────
    router.get('/fonts/<filename>', _font);
    router.get('/', _page);
    router.get('/index.html', _page);

    return router.call;
  }

  // ── Bible data ────────────────────────────────────────────────────────────

  Future<Response> _index(Request request) async {
    final index = await bible.loadIndex();
    final edition = await bible.activeEdition();
    return _json(request, {
      'edition': {
        'id': bible.activeEditionId,
        'title': edition?.title ?? bible.activeEditionId,
        'titleEn': edition?.titleEn ?? '',
        'abbrev': edition?.abbrev ?? '',
        'language': edition?.language ?? '',
        'languageName': edition?.languageName ?? '',
      },
      'books': [for (final e in index) _bookEntryJson(e)],
    });
  }

  Future<Response> _fonts(Request request) async =>
      _json(request, {'fonts': [for (final f in kWebFonts) f.toJson()]});

  Future<Response> _book(Request request, String id) async {
    final entry = await _resolvePathBook(id);
    if (entry == null) return _error(404, 'No book "$id" in this edition');
    final book = await bible.loadBook(entry);
    return _json(request, {
      'book': _bookEntryJson(entry),
      'chapters': [for (final c in book.chapters) _chapterJson(c)],
    });
  }

  /// One chapter. What the web reader actually uses — a reader looks at a
  /// chapter at a time, and shipping only that keeps Psalms as quick to open as
  /// Jude.
  Future<Response> _chapter(Request request, String id, String chapter) async {
    final n = int.tryParse(chapter);
    if (n == null) return _error(400, 'Chapter must be a number');

    final entry = await _resolvePathBook(id);
    if (entry == null) return _error(404, 'No book "$id" in this edition');

    final book = await bible.loadBook(entry);
    final found =
        book.chapters.where((c) => c.chapterNumber == n).firstOrNull;
    if (found == null) {
      return _error(404, 'No chapter $n in ${entry.bookNameEn}');
    }
    return _json(request, {
      'book': _bookEntryJson(entry),
      'chapter': _chapterJson(found),
    });
  }

  /// Resolves a book named in the URL path.
  ///
  /// The web reader addresses books by USFM id, which is ASCII, but the routes
  /// accept any name the rest of the app accepts — and "ኦሪት ዘፍጥረት" reaches the
  /// handler percent-encoded. Decoding is a second attempt rather than the
  /// first so that a name legitimately containing a `%` still resolves.
  Future<BookIndexEntry?> _resolvePathBook(String raw) async {
    final direct = await bible.resolveBook(raw);
    if (direct != null) return direct;
    try {
      final decoded = Uri.decodeComponent(raw);
      if (decoded != raw) return await bible.resolveBook(decoded);
    } on ArgumentError {
      // Not valid percent-encoding; the first attempt was the only one.
    }
    return null;
  }

  static Map<String, dynamic> _bookEntryJson(BookIndexEntry e) => {
        'id': e.id,
        'bookNumber': e.bookNumber,
        'canonOrd': e.canonOrd,
        'nameAm': e.bookNameAm,
        'nameEn': e.bookNameEn,
        'shortAm': e.bookShortNameAm,
        'shortEn': e.bookShortNameEn,
        'nativeName': e.nativeName,
        'testament': e.testament,
        'section': e.section,
        'chapterCount': e.chapterCount,
        'verseCount': e.verseCount,
      };

  static Map<String, dynamic> _chapterJson(Chapter c) => {
        'n': c.chapterNumber,
        'alt': c.alt,
        'sections': [
          for (final s in c.sections)
            {
              'title': s.title,
              'headings': [
                for (final h in s.headings)
                  {'kind': h.kind.name, 'style': h.style, 'text': h.text},
              ],
              'verses': [for (final v in s.verses) _verseJson(v)],
            },
        ],
      };

  static Map<String, dynamic> _verseJson(Verse v) => {
        'ord': v.ord,
        // The negative sentinel for unnumbered verses is kept as-is: the
        // browser needs the same key the annotation tables use, and `numbered`
        // tells it not to print one.
        'verse': v.verseNumber,
        'numbered': v.isNumbered,
        'label': v.label,
        'alt': v.alt,
        'text': v.text,
        if (v.lines.isNotEmpty)
          'lines': [
            for (final l in v.lines) {'style': l.style, 'text': l.text},
          ],
        if (v.refs.isNotEmpty)
          'refs': [
            for (final r in v.refs) {'origin': r.origin, 'target': r.target},
          ],
        if (v.notes.isNotEmpty)
          'notes': [
            for (final n in v.notes) {'caller': n.caller, 'body': n.body},
          ],
      };

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  Future<Response> _listBookmarks(Request request) async {
    final rows = await db.getAllBookmarks();
    return _json(request, {
      'bookmarks': [
        for (final b in rows)
          {
            'id': b.id,
            'bookId': b.bookId,
            'bookNumber': b.bookNumber,
            'chapter': b.chapter,
            'verseStart': b.verseStart,
            'verseCount': b.verseCount,
            'createdAt': b.createdAt.toIso8601String(),
            'updatedAt': b.updatedAt.toIso8601String(),
          },
      ],
    });
  }

  Future<Response> _createBookmark(Request request) async {
    final body = await _body(request);
    if (body == null) return _error(400, 'Body must be a JSON object');
    final ref = await _reference(body);
    if (ref is Response) return ref;
    final r = ref as _VerseRef;

    final now = DateTime.now();
    await db.insertBookmark(Bookmark(
      bookId: r.bookId,
      bookNumber: r.bookNumber,
      chapter: r.chapter,
      verseStart: r.verseStart,
      verseCount: r.verseCount,
      createdAt: now,
      updatedAt: now,
    ));

    // The insert does not hand back a row id, and the browser needs one to be
    // able to delete what it just made — so the created row is read back.
    final created = (await db.getBookmarks(r.bookId, r.chapter))
        .where((b) => b.verseStart == r.verseStart)
        .firstOrNull;
    if (created == null) return _error(500, 'Bookmark was not stored');
    return _json(request, {
      'id': created.id,
      'bookId': created.bookId,
      'bookNumber': created.bookNumber,
      'chapter': created.chapter,
      'verseStart': created.verseStart,
      'verseCount': created.verseCount,
      'createdAt': created.createdAt.toIso8601String(),
      'updatedAt': created.updatedAt.toIso8601String(),
    }, status: 201);
  }

  Future<Response> _deleteBookmark(Request request, String id) async {
    final rowId = int.tryParse(id);
    if (rowId == null) return _error(400, 'Id must be a number');
    final existing =
        (await db.getAllBookmarks()).where((b) => b.id == rowId).firstOrNull;
    if (existing == null) return _error(404, 'No bookmark $rowId');
    // Soft delete, exactly as the app does it: a row the server already knows
    // about has to survive locally as `pendingDelete` until the sync layer has
    // told the server, or the next pull would resurrect it.
    await db.softDeleteBookmark(rowId, hasRemoteId: existing.remoteId != null);
    return Response(204);
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  Future<Response> _listHighlights(Request request) async {
    final rows = await db.getAllHighlights();
    return _json(request, {
      'highlights': [for (final h in rows) _highlightJson(h)],
    });
  }

  Future<Response> _createHighlight(Request request) async {
    final body = await _body(request);
    if (body == null) return _error(400, 'Body must be a JSON object');
    final ref = await _reference(body);
    if (ref is Response) return ref;
    final r = ref as _VerseRef;

    final color = _parseColor(body['color']);
    if (color == null) {
      return _error(400, 'color must be a hex string like "#FFE062"');
    }

    final now = DateTime.now();
    final existing = (await db.getHighlights(r.bookId, r.chapter))
        .where((h) => h.verseStart == r.verseStart)
        .firstOrNull;

    if (existing != null) {
      // Re-highlighting a verse recolours it rather than stacking a second row,
      // which is what the reader's own colour picker does.
      await db.updateHighlight(existing.copyWith(
        color: color,
        updatedAt: now,
        syncStatus: existing.syncStatus == SyncStatus.synced
            ? SyncStatus.pendingUpdate
            : existing.syncStatus,
      ));
    } else {
      await db.insertHighlight(Highlight(
        bookId: r.bookId,
        bookNumber: r.bookNumber,
        chapter: r.chapter,
        verseStart: r.verseStart,
        verseCount: r.verseCount,
        color: color,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final saved = (await db.getHighlights(r.bookId, r.chapter))
        .where((h) => h.verseStart == r.verseStart)
        .firstOrNull;
    if (saved == null) return _error(500, 'Highlight was not stored');
    return _json(request, _highlightJson(saved),
        status: existing != null ? 200 : 201);
  }

  Future<Response> _deleteHighlight(Request request, String id) async {
    final rowId = int.tryParse(id);
    if (rowId == null) return _error(400, 'Id must be a number');
    final existing =
        (await db.getAllHighlights()).where((h) => h.id == rowId).firstOrNull;
    if (existing == null) return _error(404, 'No highlight $rowId');
    await db.softDeleteHighlight(rowId, hasRemoteId: existing.remoteId != null);
    return Response(204);
  }

  static Map<String, dynamic> _highlightJson(Highlight h) => {
        'id': h.id,
        'bookId': h.bookId,
        'bookNumber': h.bookNumber,
        'chapter': h.chapter,
        'verseStart': h.verseStart,
        'verseCount': h.verseCount,
        'color': _hex(h.color),
        'note': h.note,
        'createdAt': h.createdAt.toIso8601String(),
        'updatedAt': h.updatedAt.toIso8601String(),
      };

  // ── Notes ─────────────────────────────────────────────────────────────────

  Future<Response> _listNotes(Request request) async {
    final rows = await db.getAllNotes();
    return _json(request, {'notes': [for (final n in rows) _noteJson(n)]});
  }

  Future<Response> _createNote(Request request) async {
    final body = await _body(request);
    if (body == null) return _error(400, 'Body must be a JSON object');
    final ref = await _reference(body);
    if (ref is Response) return ref;
    final r = ref as _VerseRef;

    final content = (body['content'] ?? body['text']) as String?;
    if (content == null || content.trim().isEmpty) {
      return _error(400, 'content must be a non-empty string');
    }

    final now = DateTime.now();
    await db.insertNote(Note(
      bookId: r.bookId,
      bookNumber: r.bookNumber,
      chapter: r.chapter,
      verseStart: r.verseStart,
      verseCount: r.verseCount,
      content: content,
      createdAt: now,
      updatedAt: now,
    ));

    // Nothing stops a verse carrying more than one note, and `getNotes` has no
    // ORDER BY — so the one just written is identified by the highest id
    // rather than by position.
    final candidates = (await db.getNotes(r.bookId, r.chapter))
        .where((n) => n.verseStart == r.verseStart && n.id != null);
    if (candidates.isEmpty) return _error(500, 'Note was not stored');
    final created =
        candidates.reduce((a, b) => (a.id! >= b.id!) ? a : b);
    return _json(request, _noteJson(created), status: 201);
  }

  Future<Response> _updateNote(Request request, String id) async {
    final rowId = int.tryParse(id);
    if (rowId == null) return _error(400, 'Id must be a number');
    final body = await _body(request);
    if (body == null) return _error(400, 'Body must be a JSON object');

    final content = (body['content'] ?? body['text']) as String?;
    if (content == null || content.trim().isEmpty) {
      return _error(400, 'content must be a non-empty string');
    }

    final existing =
        (await db.getAllNotes()).where((n) => n.id == rowId).firstOrNull;
    if (existing == null) return _error(404, 'No note $rowId');

    await db.updateNote(existing.copyWith(
      content: content,
      updatedAt: DateTime.now(),
      syncStatus: existing.syncStatus == SyncStatus.synced
          ? SyncStatus.pendingUpdate
          : existing.syncStatus,
    ));

    final saved =
        (await db.getAllNotes()).where((n) => n.id == rowId).firstOrNull;
    if (saved == null) return _error(500, 'Note was not stored');
    return _json(request, _noteJson(saved));
  }

  Future<Response> _deleteNote(Request request, String id) async {
    final rowId = int.tryParse(id);
    if (rowId == null) return _error(400, 'Id must be a number');
    final existing =
        (await db.getAllNotes()).where((n) => n.id == rowId).firstOrNull;
    if (existing == null) return _error(404, 'No note $rowId');
    await db.softDeleteNote(rowId, hasRemoteId: existing.remoteId != null);
    return Response(204);
  }

  static Map<String, dynamic> _noteJson(Note n) => {
        'id': n.id,
        'bookId': n.bookId,
        'bookNumber': n.bookNumber,
        'chapter': n.chapter,
        'verseStart': n.verseStart,
        'verseCount': n.verseCount,
        'content': n.content,
        'isPrivate': n.isPrivate,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };

  // ── Static assets ─────────────────────────────────────────────────────────

  Future<Response> _page(Request request) async {
    try {
      final html = await rootBundle.loadString('assets/web_reader/index.html');
      return _bytes(
        request,
        utf8.encode(html),
        'text/html; charset=utf-8',
        // The page is rebuilt with the app, and a stale copy would talk to an
        // API that has moved on.
        cache: 'no-store',
      );
    } on Object catch (e) {
      debugPrint('[WebReader] index.html: $e');
      return _error(500, 'Web reader page is missing from the bundle');
    }
  }

  Future<Response> _font(Request request, String filename) async {
    if (!kServableFontFiles.contains(filename)) {
      return _error(404, 'Unknown font');
    }
    try {
      final data = await rootBundle.load('$kFontAssetDir/$filename');
      return _bytes(
        request,
        data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
        fontMimeType(filename),
        // Fonts are immutable for the life of a build and are the largest thing
        // served, so they are the one response worth caching hard.
        cache: 'public, max-age=604800',
        // Already-compressed binary; gzip would only cost CPU.
        compress: false,
      );
    } on Object catch (e) {
      debugPrint('[WebReader] font $filename: $e');
      return _error(404, 'Font not in bundle');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _body(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  /// Validates the book/chapter/verse a write is aimed at.
  ///
  /// Returns a [Response] instead of a [_VerseRef] when something is wrong, so
  /// the caller can return it directly. The book is resolved against the active
  /// edition rather than trusted: a bad id would otherwise write an annotation
  /// keyed to a book that does not exist, which no screen could ever show.
  Future<Object> _reference(Map<String, dynamic> body) async {
    final rawBook = body['bookId'] ?? body['book'] ?? body['bookNumber'];
    if (rawBook == null) return _error(400, 'bookId is required');

    final entry = await bible.resolveBook('$rawBook');
    if (entry == null) {
      return _error(404, 'No book "$rawBook" in this edition');
    }

    final chapter = _int(body['chapter']);
    if (chapter == null || chapter < 1) {
      return _error(400, 'chapter must be a positive number');
    }

    final verseStart = _int(body['verseStart'] ?? body['verse']);
    if (verseStart == null) {
      return _error(400, 'verseStart must be a number');
    }

    final verseCount = _int(body['verseCount']) ?? 1;
    if (verseCount < 1) return _error(400, 'verseCount must be at least 1');

    return _VerseRef(
      bookId: entry.id,
      bookNumber: entry.bookNumber,
      chapter: chapter,
      verseStart: verseStart,
      verseCount: verseCount,
    );
  }

  static int? _int(Object? v) => switch (v) {
        int i => i,
        String s => int.tryParse(s),
        double d => d.toInt(),
        _ => null,
      };

  /// `#RRGGBB` or `#AARRGGBB`, with or without the hash.
  static Color? _parseColor(Object? raw) {
    if (raw is int) return Color(raw);
    if (raw is! String) return null;
    final hex = raw.replaceFirst('#', '').trim();
    if (hex.length != 6 && hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(hex.length == 6 ? 0xFF000000 | value : value);
  }

  static String _hex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Response _notFound(Request request) =>
      _error(404, 'No route for /${request.url.path}');

  static Response _error(int status, String message) => Response(
        status,
        body: jsonEncode({'error': message}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  static Response _json(Request request, Object? payload, {int status = 200}) =>
      _bytes(
        request,
        utf8.encode(jsonEncode(payload)),
        'application/json; charset=utf-8',
        status: status,
        cache: 'no-store',
      );

  /// Writes a body, gzipping it when it is worth the CPU and the client said it
  /// could take it.
  static Response _bytes(
    Request request,
    List<int> body,
    String contentType, {
    int status = 200,
    String? cache,
    bool compress = true,
  }) {
    final acceptsGzip = (request.headers['accept-encoding'] ?? '')
        .toLowerCase()
        .contains('gzip');
    final useGzip = compress && acceptsGzip && body.length >= _gzipThreshold;
    final payload = useGzip ? gzip.encode(body) : body;

    return Response(
      status,
      body: payload,
      headers: {
        'content-type': contentType,
        if (useGzip) 'content-encoding': 'gzip',
        'cache-control': ?cache,
      },
    );
  }
}

class _VerseRef {
  const _VerseRef({
    required this.bookId,
    required this.bookNumber,
    required this.chapter,
    required this.verseStart,
    required this.verseCount,
  });

  final String bookId;
  final int bookNumber;
  final int chapter;
  final int verseStart;
  final int verseCount;
}
