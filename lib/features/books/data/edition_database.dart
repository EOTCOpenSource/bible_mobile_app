import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'models/book.dart';

/// A row from an edition's `book` table.
class EditionBookRow {
  const EditionBookRow({
    required this.id,
    required this.ord,
    required this.position,
    required this.name,
    required this.abbr,
    required this.chapters,
    required this.verses,
  });

  final String id;

  /// Canon position, stable across editions.
  final int ord;

  /// This edition's own display order.
  final int position;

  final String name;
  final String abbr;
  final int chapters;
  final int verses;
}

/// A verse hit from the full-text index.
class VerseRow {
  const VerseRow({
    required this.book,
    required this.chapter,
    required this.ord,
    required this.verseNumber,
    required this.label,
    required this.text,
    this.alt,
  });

  final String book;
  final int chapter;
  final int ord;
  final int verseNumber;
  final String label;
  final String text;
  final String? alt;
}

/// Read-only access to one edition's database.
///
/// Opened [OpenMode.readOnly] so SQLite never creates `-wal`/`-shm` files
/// beside a database we only read. The sync layer opens its own writable
/// connection for the duration of a patch and closes it again.
class EditionDatabase {
  EditionDatabase({required this.editionId, required this.path});

  final String editionId;
  final String path;

  Database? _db;
  List<EditionBookRow>? _books;

  Database get _handle =>
      _db ??= sqlite3.open(path, mode: OpenMode.readOnly);

  /// `meta` as a plain map.
  Map<String, String> meta() {
    final rows = _handle.select('SELECT key, value FROM meta');
    return {
      for (final r in rows) r['key'] as String: (r['value'] as String?) ?? '',
    };
  }

  int get revision =>
      int.tryParse(meta()['revision'] ?? '') ?? 0;

  /// Books in this edition's display order.
  List<EditionBookRow> books() {
    final cached = _books;
    if (cached != null) return cached;
    final rows = _handle.select(
      'SELECT id, ord, position, name, abbr, chapters, verses '
      'FROM book ORDER BY position',
    );
    return _books = rows
        .map((r) => EditionBookRow(
              id: r['id'] as String,
              ord: (r['ord'] as int?) ?? 0,
              position: (r['position'] as int?) ?? 0,
              name: (r['name'] as String?) ?? '',
              abbr: (r['abbr'] as String?) ?? '',
              chapters: (r['chapters'] as int?) ?? 0,
              verses: (r['verses'] as int?) ?? 0,
            ))
        .toList(growable: false);
  }

  /// Chapter numbers present for a book, in order.
  List<int> chapterNumbers(String bookId) {
    final rows = _handle.select(
      'SELECT n FROM chapter WHERE book = ? ORDER BY n',
      [bookId],
    );
    return rows.map((r) => (r['n'] as int?) ?? 0).toList(growable: false);
  }

  /// Every chapter of a book, verses grouped into sections by the edition's
  /// positional headings.
  List<Chapter> loadChapters(String bookId) {
    final verseRows = _handle.select(
      'SELECT chapter, ord, verse, label, alt, text, lines, refs, notes '
      'FROM verse WHERE book = ? ORDER BY chapter, ord',
      [bookId],
    );
    final headingRows = _handle.select(
      'SELECT chapter, before, ord, kind, style, text '
      'FROM heading WHERE book = ? ORDER BY chapter, ord',
      [bookId],
    );
    final chapterRows = _handle.select(
      'SELECT n, alt FROM chapter WHERE book = ? ORDER BY n',
      [bookId],
    );

    final versesByChapter = <int, List<Verse>>{};
    for (final r in verseRows) {
      final ord = (r['ord'] as int?) ?? 0;
      final number = r['verse'] as int?;
      versesByChapter.putIfAbsent((r['chapter'] as int?) ?? 0, () => []).add(
            Verse(
              ord: ord,
              // Unnumbered verses get a negative sentinel; see [Verse].
              verseNumber: number ?? -(ord + 1),
              label: (r['label'] as String?) ?? '',
              alt: r['alt'] as String?,
              text: (r['text'] as String?) ?? '',
              lines: decodeJsonList(r['lines'], VerseLine.fromJson),
              refs: decodeJsonList(r['refs'], CrossRef.fromJson),
              notes: decodeJsonList(r['notes'], VerseNote.fromJson),
            ),
          );
    }

    final headingsByChapter = <int, List<Heading>>{};
    for (final r in headingRows) {
      headingsByChapter.putIfAbsent((r['chapter'] as int?) ?? 0, () => []).add(
            Heading(
              kind: HeadingKind.parse(r['kind'] as String?),
              style: (r['style'] as String?) ?? '',
              text: (r['text'] as String?) ?? '',
              before: r['before'] as int?,
            ),
          );
    }

    final chapterAlt = {
      for (final r in chapterRows) (r['n'] as int?) ?? 0: r['alt'] as String?,
    };

    return [
      for (final r in chapterRows)
        () {
          final n = (r['n'] as int?) ?? 0;
          return Chapter(
            chapterNumber: n,
            alt: chapterAlt[n],
            sections: _buildSections(
              versesByChapter[n] ?? const [],
              headingsByChapter[n] ?? const [],
            ),
          );
        }(),
    ];
  }

  /// Splits a chapter's verses at its heading boundaries.
  ///
  /// `heading.before` is the verse number a heading precedes; null means end of
  /// chapter. Headings that land before the first verse join section 0 instead
  /// of opening an empty one, which is what the reader's chapter header expects.
  static List<Section> _buildSections(
    List<Verse> verses,
    List<Heading> headings,
  ) {
    final byBefore = <int, List<Heading>>{};
    final trailing = <Heading>[];
    for (final h in headings) {
      if (h.before == null) {
        trailing.add(h);
      } else {
        byBefore.putIfAbsent(h.before!, () => []).add(h);
      }
    }

    final sections = <Section>[];
    var currentHeadings = <Heading>[];
    var currentVerses = <Verse>[];

    void flush() {
      if (currentVerses.isEmpty && currentHeadings.isEmpty) return;
      sections.add(Section(
        title: currentHeadings
                .where((h) => h.kind == HeadingKind.section)
                .map((h) => h.text)
                .firstOrNull ??
            '',
        headings: List.unmodifiable(currentHeadings),
        verses: List.unmodifiable(currentVerses),
      ));
      currentHeadings = <Heading>[];
      currentVerses = <Verse>[];
    }

    for (final verse in verses) {
      final starting = byBefore[verse.verseNumber];
      if (starting != null && starting.isNotEmpty) {
        // Only break when verses have accumulated; otherwise these headings
        // belong to the section we are already opening.
        if (currentVerses.isNotEmpty) flush();
        currentHeadings.addAll(starting);
      }
      currentVerses.add(verse);
    }
    flush();

    if (trailing.isNotEmpty) {
      sections.add(Section(
        title: trailing
                .where((h) => h.kind == HeadingKind.section)
                .map((h) => h.text)
                .firstOrNull ??
            '',
        headings: List.unmodifiable(trailing),
        verses: const [],
      ));
    }

    // A chapter with no headings at all still needs one section to render.
    if (sections.isEmpty) {
      sections.add(Section(title: '', verses: List.unmodifiable(verses)));
    }
    return sections;
  }

  /// One verse by reference, or null when the edition does not have it.
  ///
  /// Versification differs between editions — Genesis 1 is 31 verses in Amharic
  /// and 30 in Tigrinya — so a miss here is normal, not an error.
  VerseRow? verseAt(String bookId, int chapter, int verse) {
    final rows = _handle.select(
      'SELECT book, chapter, ord, verse, label, alt, text FROM verse '
      'WHERE book = ? AND chapter = ? AND verse = ? LIMIT 1',
      [bookId, chapter, verse],
    );
    return rows.isEmpty ? null : _verseRow(rows.first);
  }

  /// All verses of a chapter, ordered by `ord`.
  List<VerseRow> chapterVerses(String bookId, int chapter) {
    final rows = _handle.select(
      'SELECT book, chapter, ord, verse, label, alt, text FROM verse '
      'WHERE book = ? AND chapter = ? ORDER BY ord',
      [bookId, chapter],
    );
    return rows.map(_verseRow).toList(growable: false);
  }

  static VerseRow _verseRow(Row r) {
    final ord = (r['ord'] as int?) ?? 0;
    final number = r['verse'] as int?;
    return VerseRow(
      book: r['book'] as String,
      chapter: (r['chapter'] as int?) ?? 0,
      ord: ord,
      verseNumber: number ?? -(ord + 1),
      label: (r['label'] as String?) ?? '',
      alt: r['alt'] as String?,
      text: (r['text'] as String?) ?? '',
    );
  }

  // ── Full-text search ───────────────────────────────────────────────────────

  /// Turns raw user input into a safe FTS5 query.
  ///
  /// `*`, `-`, `:`, `AND`, `OR` and `NEAR` are query syntax, so a reader typing
  /// `ሰው-` would otherwise get a parse error rather than results. Wrapping each
  /// term in double quotes makes it a literal phrase; internal quotes are
  /// doubled, which is how FTS5 escapes them.
  static String ftsQuery(String input, {required bool allWords}) {
    String quote(String term) => '"${term.replaceAll('"', '""')}"';

    final trimmed = input.trim();
    if (!allWords) return quote(trimmed);

    final terms = trimmed
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(quote);
    return terms.join(' AND ');
  }

  /// Ranked search over `verse_fts`.
  ///
  /// [books] scopes to a set of USFM ids; empty means the whole edition. Always
  /// paginated — common Amharic terms match ten thousand verses.
  List<VerseRow> search(
    String match, {
    Set<String> books = const {},
    int limit = 100,
    int offset = 0,
  }) {
    final scoped = books.isNotEmpty;
    final placeholders = scoped
        ? List.filled(books.length, '?').join(', ')
        : '';
    final sql = '''
      SELECT v.book, v.chapter, v.ord, v.verse, v.label, v.alt, v.text
        FROM verse_fts JOIN verse v ON v.id = verse_fts.rowid
       WHERE verse_fts MATCH ?
       ${scoped ? 'AND v.book IN ($placeholders)' : ''}
       ORDER BY rank
       LIMIT ? OFFSET ?
    ''';

    try {
      final rows = _handle.select(sql, [
        match,
        if (scoped) ...books,
        limit,
        offset,
      ]);
      return rows.map(_verseRow).toList(growable: false);
    } on SqliteException catch (e) {
      // A malformed MATCH is a user-input problem, not a crash.
      debugPrint('[EditionDatabase] search failed for $match: $e');
      return const [];
    }
  }

  void dispose() {
    try {
      _db?.close();
    } on Object catch (e) {
      debugPrint('[EditionDatabase] dispose: $e');
    }
    _db = null;
    _books = null;
  }
}
