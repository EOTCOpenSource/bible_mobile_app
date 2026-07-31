import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bible_storage.dart';
import '../catalog_database.dart';
import '../edition_database.dart';
import '../models/book.dart';
import '../models/book_identity.dart';
import '../models/book_index_entry.dart';
import '../models/edition.dart';

class DailyVerseResult {
  final String text;
  final String bookNameAm;
  final String bookNameEn;
  final int chapter;
  final int verse;
  final BookIndexEntry bookEntry;

  const DailyVerseResult({
    required this.text,
    required this.bookNameAm,
    required this.bookNameEn,
    required this.chapter,
    required this.verse,
    required this.bookEntry,
  });
}

class SearchHit {
  final BookIndexEntry bookEntry;
  final int chapter;
  final int verse;
  final String text;
  final int matchStart;
  final int matchEnd;

  const SearchHit({
    required this.bookEntry,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.matchStart,
    required this.matchEnd,
  });
}

enum SearchMode { smart, allWords }

enum SearchScope { all, oldTestament, newTestament, deuterocanonical }

class SearchFilter {
  const SearchFilter({
    this.mode = SearchMode.smart,
    this.scope = SearchScope.all,
    this.book,
  });
  final SearchMode mode;
  final SearchScope scope;
  final BookIndexEntry? book;
}

/// Reads scripture out of the active edition's SQLite database.
///
/// One edition is active at a time. `am-2000` ships with the app and is always
/// installable offline; the other eight are downloaded on demand. Switching
/// editions swaps the open database and drops every derived cache — book names,
/// aliases and loaded books are all edition-specific.
///
/// A [ChangeNotifier] so the edition picker can rebuild the app's book lists
/// without threading a callback through every screen.
class BibleRepository extends ChangeNotifier {
  BibleRepository({BibleStorage? storage})
      : storage = storage ?? BibleStorage() {
    catalog = CatalogDatabase(this.storage);
  }

  static const _prefsActiveEdition = 'active_edition_id';
  static const _dailyVersesAsset =
      'assets/bibledata/ethiopian_daily_verses.json';

  final BibleStorage storage;
  late final CatalogDatabase catalog;

  EditionDatabase? _edition;
  String _activeEditionId = BibleStorage.bundledEditionId;

  List<BookIndexEntry>? _index;
  Map<String, BookIndexEntry>? _byId;
  Map<String, BookIndexEntry>? _aliases;
  final Map<String, Book> _bookCache = {};

  Map<String, Map<String, dynamic>>? _dailyVerseIndex;
  List<Map<String, dynamic>>? _dailyVerseList;

  String get activeEditionId => _activeEditionId;

  /// Unpacks the bundled assets and opens the last-used edition.
  ///
  /// Falls back to the bundled edition when the remembered one has been
  /// deleted, so an uninstall can never leave the app with no scripture.
  Future<void> init() async {
    await storage.ensureBundledInstalled();

    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getString(_prefsActiveEdition);
    final target =
        remembered != null && await storage.isInstalled(remembered)
            ? remembered
            : BibleStorage.bundledEditionId;

    await _openEdition(target);
  }

  Future<void> _openEdition(String id) async {
    _edition?.dispose();
    final file = await storage.editionFile(id);
    _edition = EditionDatabase(editionId: id, path: file.path);
    _activeEditionId = id;
    _resetCaches();
  }

  void _resetCaches() {
    _index = null;
    _byId = null;
    _aliases = null;
    _bookCache.clear();
  }

  EditionDatabase get _db {
    final db = _edition;
    if (db == null) {
      throw StateError('BibleRepository.init() has not completed');
    }
    return db;
  }

  /// Switches the active edition and persists the choice.
  ///
  /// No-ops when [id] is already active or is not installed — the caller is UI,
  /// and a missing database is a state the download screen owns, not an error
  /// worth throwing into a widget build.
  Future<bool> switchEdition(String id) async {
    if (id == _activeEditionId) return true;
    if (!await storage.isInstalled(id)) return false;

    await _openEdition(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsActiveEdition, id);
    notifyListeners();
    return true;
  }

  /// Called after an edition is deleted, so an active edition that just went
  /// away is replaced rather than left dangling.
  Future<void> handleEditionRemoved(String id) async {
    if (id != _activeEditionId) return;
    await _openEdition(BibleStorage.bundledEditionId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsActiveEdition, BibleStorage.bundledEditionId);
    notifyListeners();
  }

  /// Reopens the active edition — used after patches are applied so the
  /// read-only connection sees the new text.
  Future<void> reloadActiveEdition() async {
    await _openEdition(_activeEditionId);
    notifyListeners();
  }

  Future<Edition?> activeEdition() => catalog.edition(_activeEditionId);

  // ── Book index ─────────────────────────────────────────────────────────────

  /// Books of the active edition in its own display order.
  ///
  /// Names come from `catalog.db` in the app's two UI languages, falling back
  /// to the edition's own name where the catalog has no entry — `om` and `ti`
  /// only name the protestant 66, and no catalog language names every book of
  /// every edition.
  Future<List<BookIndexEntry>> loadIndex() async {
    final cached = _index;
    if (cached != null) return cached;

    final amNames = await catalog.namesFor('am');
    final enNames = await catalog.namesFor('en');
    final canonById = await catalog.canonById();

    final entries = _db.books().map((b) {
      final am = amNames[b.id];
      final en = enNames[b.id];
      final canon = canonById[b.id];
      return BookIndexEntry(
        id: b.id,
        bookNumber: b.position,
        canonOrd: canon?.ord ?? b.ord,
        bookNameAm: am?.name.isNotEmpty == true ? am!.name : b.name,
        bookNameEn: en?.name.isNotEmpty == true ? en!.name : b.name,
        bookShortNameAm: am?.abbr.isNotEmpty == true ? am!.abbr : b.abbr,
        // The catalog has no English abbreviations — every `en` row's `abbr`
        // is NULL — so this comes from the frozen table, not the edition,
        // whose own abbreviation is Ethiopic for the Amharic editions.
        bookShortNameEn: enAbbrevFromUsfm(b.id),
        nativeName: b.name,
        testament: canon?.testament ?? '',
        section: canon?.section,
        chapterCount: b.chapters,
        verseCount: b.verses,
      );
    }).toList(growable: false);

    _byId = {for (final e in entries) e.id: e};
    return _index = entries;
  }

  /// The book with this USFM id in the active edition, or null when the
  /// edition does not contain it.
  Future<BookIndexEntry?> bookById(String usfmId) async {
    await loadIndex();
    return _byId?[usfmId];
  }

  /// Resolves anything that might name a book — USFM id, legacy English name,
  /// API kebab id — to an entry in the active edition.
  Future<BookIndexEntry?> resolveBook(String raw) async {
    final direct = await bookById(usfmFromAnyBookId(raw));
    if (direct != null) return direct;
    final table = await _aliasTable();
    return table[_bookKey(raw)];
  }

  Future<Book> loadBook(BookIndexEntry entry) async {
    final cached = _bookCache[entry.id];
    if (cached != null) return cached;

    final book = Book(
      id: entry.id,
      bookNumber: entry.bookNumber,
      bookNameAm: entry.bookNameAm,
      bookNameEn: entry.bookNameEn,
      bookShortNameAm: entry.bookShortNameAm,
      bookShortNameEn: entry.bookShortNameEn,
      nativeName: entry.nativeName,
      testament: entry.testament,
      chapters: _db.loadChapters(entry.id),
    );
    return _bookCache[entry.id] = book;
  }

  /// Text of a single verse, without paying to materialise the whole book.
  Future<String?> verseText(String usfmId, int chapter, int verse) async {
    final row = _db.verseAt(usfmId, chapter, verse);
    return row?.text;
  }

  /// Verses of one chapter, for callers that only need text and numbers.
  Future<List<VerseRow>> chapterVerses(String usfmId, int chapter) async =>
      _db.chapterVerses(usfmId, chapter);

  /// Chapter count for a book in the active edition, 0 when absent.
  Future<int> chapterCount(String usfmId) async {
    final entry = await bookById(usfmId);
    return entry?.chapterCount ?? 0;
  }

  // ── Name resolution ────────────────────────────────────────────────────────

  /// Collapses a book name to a comparison key: lowercase, letters/digits and
  /// Ethiopic syllables only. "Book of Tobit", "book-of-tobit" and "BookOfTobit"
  /// all collapse to the same key.
  static String _bookKey(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ሀ-፿]'), '');

  /// Every alias under which a book may be referenced by curated data (daily
  /// verses, reading plans) or by data written before the SQLite migration.
  ///
  /// Deliberately generous: the curated files name books by canon slug
  /// ("Ezra Sutuel", "Kufale", "Yodit"), by legacy English name, and by
  /// abbreviation ("Act"), and all of those have to land on the same book.
  Future<Map<String, BookIndexEntry>> _aliasTable() async {
    final cached = _aliases;
    if (cached != null) return cached;

    final index = await loadIndex();
    final canonById = await catalog.canonById();
    final table = <String, BookIndexEntry>{};

    void add(String alias, BookIndexEntry entry) {
      final key = _bookKey(alias);
      if (key.isEmpty) return;
      // First alias wins: earlier books claim ambiguous keys in canon order,
      // which is the same precedence the JSON index had.
      table.putIfAbsent(key, () => entry);
    }

    for (final entry in index) {
      add(entry.id, entry);
      add(entry.bookNameEn, entry);
      add(
        entry.bookNameEn
            .toLowerCase()
            .replaceFirst(RegExp(r'^(the\s+)?book\s+of\s+'), ''),
        entry,
      );
      add(entry.bookNameAm, entry);
      add(entry.bookNameAm.replaceFirst(RegExp(r'^መጽሐፈ\s+'), ''), entry);
      add(entry.bookShortNameEn, entry);
      add(entry.bookShortNameAm, entry);
      add(entry.nativeName, entry);

      final canon = canonById[entry.id];
      if (canon != null) {
        add(canon.slug, entry);
        add(canon.nameEn, entry);
      }

      final legacy = kUsfmToLegacyName[entry.id];
      if (legacy != null) {
        add(legacy, entry);
        add(
          legacy
              .toLowerCase()
              .replaceFirst(RegExp(r'^(the\s+)?book\s+of\s+'), ''),
          entry,
        );
      }
    }
    return _aliases = table;
  }

  // ── Daily verse ────────────────────────────────────────────────────────────

  Future<void> _loadDailyVerseIndex() async {
    if (_dailyVerseIndex != null) return;
    final raw = await rootBundle.loadString(_dailyVersesAsset);
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final list = (root['verses'] as List).cast<Map<String, dynamic>>();
    _dailyVerseIndex = {
      for (final e in list) '${e['month']}:${e['day']}': e,
    };
    _dailyVerseList = [...list]..sort((a, b) {
        final m = (a['month'] as int).compareTo(b['month'] as int);
        return m != 0 ? m : (a['day'] as int).compareTo(b['day'] as int);
      });
    debugPrint('[DailyVerse] loaded ${_dailyVerseIndex!.length} entries');
  }

  /// Resolves one curated entry against the active edition. Returns null when
  /// the book, chapter or verse is not in this edition — versification differs
  /// between editions, so that is expected, not exceptional.
  Future<DailyVerseResult?> _resolveDailyEntry(
      Map<String, dynamic> entry) async {
    final bookName = entry['book'] as String;
    final chapterNum = entry['chapter'] as int;
    final verseNum = entry['verse'] as int;

    final bookEntry = await resolveBook(bookName);
    if (bookEntry == null) {
      debugPrint('[DailyVerse] book not in $_activeEditionId: "$bookName"');
      return null;
    }

    var row = _db.verseAt(bookEntry.id, chapterNum, verseNum);

    // Two ways the exact reference can fail to produce a card:
    //
    //  * the verse is absent — versification differs between editions, so the
    //    curated Jonah 1:17 is Jonah 1:16 here;
    //  * the verse is present but its text is empty. 134 verses in `am-2000`
    //    carry only a cross reference and no words, and seven curated days
    //    land on one.
    //
    // Both fall back to the nearest verse in the chapter that actually has
    // text, which is what a reader expects to see on the card.
    if (row == null || row.text.trim().isEmpty) {
      final verses = _db
          .chapterVerses(bookEntry.id, chapterNum)
          .where((v) => v.verseNumber > 0 && v.text.trim().isNotEmpty)
          .toList();
      if (verses.isEmpty) return null;
      final reason = row == null ? 'missing' : 'has no text';
      row = verses.reduce((a, b) =>
          (a.verseNumber - verseNum).abs() <= (b.verseNumber - verseNum).abs()
              ? a
              : b);
      debugPrint('[DailyVerse] verse $verseNum $reason in '
          '${bookEntry.bookNameEn} $chapterNum → using ${row.verseNumber}');
    }

    return DailyVerseResult(
      text: row.text,
      bookNameAm: bookEntry.bookNameAm,
      bookNameEn: bookEntry.bookNameEn,
      chapter: chapterNum,
      verse: row.verseNumber,
      bookEntry: bookEntry,
    );
  }

  /// Daily verse for an Ethiopian [month]/[day]. Never returns null unless the
  /// asset itself is unreadable: days the curated file does not cover (Pagume,
  /// and the 29th/30th of month 2) deterministically borrow another day's
  /// verse, and unresolvable entries walk forward to the next usable one.
  Future<DailyVerseResult?> loadDailyVerse(int month, int day) async {
    try {
      await _loadDailyVerseIndex();
      final list = _dailyVerseList!;
      if (list.isEmpty) return null;

      // Ethiopian year: 12 × 30 days + Pagume (5–6 days).
      final dayOfYear = (month - 1) * 30 + day;
      final exact = _dailyVerseIndex!['$month:$day'];
      final startAt =
          exact != null ? list.indexOf(exact) : (dayOfYear - 1) % list.length;
      if (exact == null) {
        debugPrint('[DailyVerse] no curated entry for $month:$day '
            '→ borrowing index $startAt');
      }

      for (var offset = 0; offset < list.length; offset++) {
        final candidate = list[(startAt + offset) % list.length];
        final result = await _resolveDailyEntry(candidate);
        if (result != null) return result;
      }
      debugPrint('[DailyVerse] no entry could be resolved');
      return null;
    } on Object catch (e, st) {
      debugPrint('[DailyVerse] error: $e\n$st');
      return null;
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  /// Full-text search over the active edition.
  ///
  /// Backed by FTS5 with the `trigram` tokenizer, which is why Amharic search
  /// works at all: እግዚአብሔር appears as የእግዚአብሔርም, ለእግዚአብሔር, እግዚአብሔርን, and a
  /// word tokenizer finds barely two thirds of what a substring scan does.
  Future<List<SearchHit>> searchVerses(
    String query, {
    SearchFilter filter = const SearchFilter(),
    int limit = 300,
    int offset = 0,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final index = await loadIndex();
    final scope = <String>{
      if (filter.book != null)
        filter.book!.id
      else
        ...switch (filter.scope) {
          SearchScope.all => const <String>[],
          SearchScope.oldTestament =>
            index.where((e) => e.isOldTestament).map((e) => e.id),
          SearchScope.newTestament =>
            index.where((e) => e.isNewTestament).map((e) => e.id),
          SearchScope.deuterocanonical =>
            index.where((e) => e.isDeuterocanonical).map((e) => e.id),
        },
    };

    final match = EditionDatabase.ftsQuery(
      q,
      allWords: filter.mode == SearchMode.allWords,
    );
    final rows = _db.search(
      match,
      books: scope,
      limit: limit,
      offset: offset,
    );

    final byId = _byId ?? {};
    final needle = filter.mode == SearchMode.allWords
        ? q.split(RegExp(r'\s+')).firstWhere((w) => w.isNotEmpty,
            orElse: () => q)
        : q;

    return [
      for (final row in rows)
        if (byId[row.book] case final entry?)
          () {
            // The UI highlights by term, but keep the offsets accurate for
            // callers that use them. -1 from indexOf collapses to an empty
            // range rather than a negative one.
            final start = row.text.indexOf(needle);
            return SearchHit(
              bookEntry: entry,
              chapter: row.chapter,
              verse: row.verseNumber,
              text: row.text,
              matchStart: start < 0 ? 0 : start,
              matchEnd: start < 0 ? 0 : start + needle.length,
            );
          }(),
    ];
  }

  void clearCache() {
    _resetCaches();
    _dailyVerseIndex = null;
    _dailyVerseList = null;
  }

  @override
  void dispose() {
    _edition?.dispose();
    catalog.dispose();
    super.dispose();
  }
}
