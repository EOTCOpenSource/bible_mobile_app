import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/cross_ref.dart';

/// Reads `crossrefs.db`, the bundled openbible.info cross references.
///
/// The database is opened lazily by [_open], which in the app unpacks the
/// bundled asset on first use (see `BibleStorage.ensureCrossRefsInstalled`).
class CrossRefRepository {
  CrossRefRepository({required Future<Database> Function() open})
      : _open = open;

  final Future<Database> Function() _open;
  Future<Database>? _db;

  Future<Database> get _database => _db ??= _open();

  /// Every passage linked from this verse, most-voted first.
  Future<List<CrossRef>> getCrossRefs(
      String book, int chapter, int verse) async {
    try {
      final db = await _database;
      final rows = db.select(
        'SELECT to_book, to_chapter, to_verse, to_chapter_end, to_verse_end, '
        'votes FROM cross_ref WHERE book = ? AND chapter = ? AND verse = ? '
        'ORDER BY votes DESC, to_book, to_chapter, to_verse',
        [book, chapter, verse],
      );
      return List.unmodifiable(rows.map((r) => CrossRef(
            book: r['to_book'] as String,
            chapter: r['to_chapter'] as int,
            verse: r['to_verse'] as int,
            toChapter: r['to_chapter_end'] as int,
            toVerse: r['to_verse_end'] as int,
            votes: r['votes'] as int,
          )));
    } on Object catch (e) {
      // A reader cannot act on a broken lookup; an empty list shows them the
      // same "nothing linked here" a verse without references does.
      debugPrint('[CrossRefRepository] lookup failed for $book $chapter:$verse: $e');
      return const [];
    }
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) (await db).close();
  }
}
