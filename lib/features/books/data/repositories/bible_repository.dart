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

  Future<DailyVerseResult?> loadDailyVerse(int month, int day) async {
    try {
      if (_dailyVerseIndex == null) {
        final raw = await rootBundle.loadString(
            '$_basePath/ethiopian_daily_verses.json');
        final root = jsonDecode(raw) as Map<String, dynamic>;
        final list = root['verses'] as List;
        _dailyVerseIndex = {
          for (final e in list)
            '${e['month']}:${e['day']}': e as Map<String, dynamic>,
        };
        debugPrint('[DailyVerse] loaded ${_dailyVerseIndex!.length} entries');
      }

      final key   = '$month:$day';
      final entry = _dailyVerseIndex![key];
      if (entry == null) {
        debugPrint('[DailyVerse] no entry for key "$key"');
        return null;
      }

      final bookName   = entry['book']    as String;
      final chapterNum = entry['chapter'] as int;
      final verseNum   = entry['verse']   as int;
      debugPrint('[DailyVerse] found $bookName $chapterNum:$verseNum for $key');

      final index     = await loadIndex();
      final bookEntry = index.cast<BookIndexEntry?>().firstWhere(
        (e) => e!.bookNameEn.toLowerCase() == bookName.toLowerCase(),
        orElse: () => null,
      );
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
        debugPrint('[DailyVerse] chapter $chapterNum not found in ${bookEntry.bookNameEn}');
        return null;
      }

      final verse = chapter.allVerses.cast<Verse?>().firstWhere(
        (v) => v!.verseNumber == verseNum,
        orElse: () => null,
      );
      if (verse == null) {
        debugPrint('[DailyVerse] verse $verseNum not found in chapter $chapterNum');
        return null;
      }

      return DailyVerseResult(
        text:       verse.text,
        bookNameAm: bookEntry.bookNameAm,
        bookNameEn: bookEntry.bookNameEn,
        chapter:    chapterNum,
        verse:      verseNum,
        bookEntry:  bookEntry,
      );
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
  }
}
