import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/book_index_entry.dart';
import '../models/book.dart';

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
enum SearchScope { all, oldTestament, newTestament }

class SearchFilter {
  const SearchFilter({
    this.mode  = SearchMode.smart,
    this.scope = SearchScope.all,
    this.book,
  });
  final SearchMode mode;
  final SearchScope scope;
  final BookIndexEntry? book;
}

class BibleRepository {
  static const _basePath = 'assets/bibledata';

  List<BookIndexEntry>? _index;
  final Map<String, Book> _bookCache = {};
  Map<String, Map<String, dynamic>>? _dailyVerseIndex;
  List<Map<String, dynamic>>? _dailyVerseList;
  Map<String, BookIndexEntry>? _bookLookup;

  Future<List<BookIndexEntry>> loadIndex() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('$_basePath/index.json');
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final list = root['files'] as List;
    _index = list
        .map((e) => BookIndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return _index!;
  }

  Future<Book> loadBook(BookIndexEntry entry) async {
    if (_bookCache.containsKey(entry.filename)) {
      return _bookCache[entry.filename]!;
    }
    final raw =
        await rootBundle.loadString('$_basePath/${entry.filename}');
    final book = Book.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _bookCache[entry.filename] = book;
    return book;
  }

  /// Collapses a book name to a comparison key: lowercase, letters/digits and
  /// Ethiopic syllables only. "Book of Tobit", "book-of-tobit" and "BookOfTobit"
  /// all collapse to the same key.
  static String _bookKey(String raw) => raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9ሀ-፿]'), '');

  /// Every alias under which a book may be referenced by curated data
  /// (daily verses, reading plans): English name, English name without a
  /// leading "book of"/"the", short names, Amharic names and the asset
  /// filename stem (`19-ezrasutuel.json` → `ezrasutuel`).
  Future<Map<String, BookIndexEntry>> _bookLookupTable() async {
    if (_bookLookup != null) return _bookLookup!;
    final index = await loadIndex();
    final table = <String, BookIndexEntry>{};

    void add(String alias, BookIndexEntry entry) {
      final key = _bookKey(alias);
      if (key.isEmpty) return;
      table.putIfAbsent(key, () => entry);
    }

    for (final entry in index) {
      add(entry.bookNameEn, entry);
      add(entry.bookNameEn
          .toLowerCase()
          .replaceFirst(RegExp(r'^(the\s+)?book\s+of\s+'), ''), entry);
      add(entry.bookNameAm, entry);
      add(entry.bookNameAm.replaceFirst(RegExp(r'^መጽሐፈ\s+'), ''), entry);
      add(entry.bookShortNameEn, entry);
      add(entry.bookShortNameAm, entry);
      // "19-ezrasutuel.json" → "ezrasutuel", "59-act.json" → "act"
      add(
        entry.filename
            .replaceFirst(RegExp(r'\.json$'), '')
            .replaceFirst(RegExp(r'^\d+\s*-\s*'), ''),
        entry,
      );
    }
    _bookLookup = table;
    return table;
  }

  Future<void> _loadDailyVerseIndex() async {
    if (_dailyVerseIndex != null) return;
    final raw =
        await rootBundle.loadString('$_basePath/ethiopian_daily_verses.json');
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

  /// Resolves one curated entry to real scripture. Returns null when the book,
  /// chapter or verse cannot be found in the bundled text.
  Future<DailyVerseResult?> _resolveDailyEntry(Map<String, dynamic> entry) async {
    final bookName   = entry['book'] as String;
    final chapterNum = entry['chapter'] as int;
    final verseNum   = entry['verse'] as int;

    final lookup    = await _bookLookupTable();
    final bookEntry = lookup[_bookKey(bookName)];
    if (bookEntry == null) {
      debugPrint('[DailyVerse] book not found in index: "$bookName"');
      return null;
    }

    final book    = await loadBook(bookEntry);
    final chapter = book.chapters.cast<Chapter?>().firstWhere(
      (c) => c!.chapterNumber == chapterNum,
      orElse: () => null,
    );
    if (chapter == null) {
      debugPrint(
          '[DailyVerse] chapter $chapterNum missing in ${bookEntry.bookNameEn}');
      return null;
    }

    final verses = chapter.allVerses;
    if (verses.isEmpty) return null;

    // Amharic versification differs slightly from the curated references
    // (e.g. Jonah 1:17), so fall back to the closest verse in the chapter
    // instead of showing nothing.
    var verse = verses.cast<Verse?>().firstWhere(
      (v) => v!.verseNumber == verseNum,
      orElse: () => null,
    );
    if (verse == null) {
      verse = verses.reduce((a, b) =>
          (a.verseNumber - verseNum).abs() <= (b.verseNumber - verseNum).abs()
              ? a
              : b);
      debugPrint('[DailyVerse] verse $verseNum missing in '
          '${bookEntry.bookNameEn} $chapterNum → using ${verse.verseNumber}');
    }

    return DailyVerseResult(
      text:       verse.text,
      bookNameAm: bookEntry.bookNameAm,
      bookNameEn: bookEntry.bookNameEn,
      chapter:    chapterNum,
      verse:      verse.verseNumber,
      bookEntry:  bookEntry,
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
      final exact     = _dailyVerseIndex!['$month:$day'];
      final startAt   = exact != null
          ? list.indexOf(exact)
          : (dayOfYear - 1) % list.length;
      if (exact == null) {
        debugPrint('[DailyVerse] no curated entry for $month:$day '
            '→ borrowing index $startAt');
      }

      for (var offset = 0; offset < list.length; offset++) {
        final candidate = list[(startAt + offset) % list.length];
        final result    = await _resolveDailyEntry(candidate);
        if (result != null) return result;
      }
      debugPrint('[DailyVerse] no entry could be resolved');
      return null;
    } catch (e, st) {
      debugPrint('[DailyVerse] error: $e\n$st');
      return null;
    }
  }

  Future<List<SearchHit>> searchVerses(
    String query, {
    SearchFilter filter = const SearchFilter(),
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final bookIndex = await loadIndex();
    final List<BookIndexEntry> scope = filter.book != null
        ? [filter.book!]
        : switch (filter.scope) {
            SearchScope.all          => bookIndex,
            SearchScope.oldTestament => bookIndex.where((e) => e.isOldTestament).toList(),
            SearchScope.newTestament => bookIndex.where((e) => !e.isOldTestament).toList(),
          };

    final books = await Future.wait(scope.map(loadBook));

    final words = filter.mode == SearchMode.allWords
        ? q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList()
        : null;

    const maxResults = 300;
    final hits = <SearchHit>[];

    for (var i = 0; i < scope.length; i++) {
      if (hits.length >= maxResults) break;
      final entry = scope[i];
      for (final chapter in books[i].chapters) {
        if (hits.length >= maxResults) break;
        for (final section in chapter.sections) {
          if (hits.length >= maxResults) break;
          for (final verse in section.verses) {
            final text = verse.text;
            int mStart;
            if (words != null) {
              if (!words.every(text.contains)) continue;
              mStart = text.indexOf(words.first);
            } else {
              mStart = text.indexOf(q);
              if (mStart < 0) continue;
            }
            hits.add(SearchHit(
              bookEntry:  entry,
              chapter:    chapter.chapterNumber,
              verse:      verse.verseNumber,
              text:       text,
              matchStart: mStart,
              matchEnd:   mStart + (words != null ? words.first.length : q.length),
            ));
          }
        }
      }
    }
    return hits;
  }

  void clearCache() {
    _bookCache.clear();
    _dailyVerseIndex = null;
    _dailyVerseList  = null;
    _bookLookup      = null;
  }
}
