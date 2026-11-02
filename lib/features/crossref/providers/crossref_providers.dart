import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../../books/data/models/book.dart' show Verse;
import '../data/models/cross_ref.dart';
import '../data/repositories/crossref_repository.dart';

/// The cross-reference database, unpacked next to the edition databases on
/// first use.
final crossRefRepositoryProvider = Provider<CrossRefRepository>((ref) {
  final storage = ref.watch(bibleRepositoryProvider).storage;
  final repository = CrossRefRepository(open: () async {
    final file = await storage.ensureCrossRefsInstalled();
    return sqlite3.open(file.path, mode: OpenMode.readOnly);
  });
  ref.onDispose(repository.close);
  return repository;
});

/// A verse, by USFM book id.
typedef CrossRefVerseQuery = ({String book, int chapter, int verse});

/// The passages linked from one verse, most-voted first.
final crossRefsForVerseProvider =
    FutureProvider.family<List<CrossRef>, CrossRefVerseQuery>((ref, query) {
  return ref
      .read(crossRefRepositoryProvider)
      .getCrossRefs(query.book, query.chapter, query.verse);
});

/// What one row shows: the book's name and the words of the passage.
@immutable
class CrossRefTarget {
  const CrossRefTarget({this.bookName, this.verses = const []});

  /// Null when the active edition does not carry the book — the row then shows
  /// the bare reference instead of an empty line.
  final String? bookName;

  /// The passage's verses in order; empty when the edition lacks them.
  final List<Verse> verses;
}

typedef CrossRefTargetQuery = ({CrossRef ref, bool amharic});

/// Resolves the name and preview text for one cross-reference row.
///
/// A provider rather than a `FutureBuilder` in the row's `build`, because a
/// future created during build is a *new* future on every rebuild: it resolves,
/// calls setState, rebuilds, starts again, and the row's height oscillates
/// between "reference only" and "reference plus preview" forever. Keyed and
/// cached here, each target is resolved once and survives the row scrolling
/// out of view and back.
final crossRefTargetProvider =
    FutureProvider.family<CrossRefTarget, CrossRefTargetQuery>((ref, q) async {
  final repo = ref.read(bibleRepositoryProvider);
  final entry = await repo.bookById(q.ref.book);
  if (entry == null) return const CrossRefTarget();

  final name = q.amharic ? entry.bookNameAm : entry.bookNameEn;
  final book = await repo.loadBook(entry);
  final verses = <Verse>[];
  for (final chapter in book.chapters) {
    final c = chapter.chapterNumber;
    if (c < q.ref.chapter || c > q.ref.toChapter) continue;
    for (final verse in chapter.allVerses) {
      final v = verse.verseNumber;
      final afterStart = c > q.ref.chapter || v >= q.ref.verse;
      final beforeEnd = c < q.ref.toChapter || v <= q.ref.toVerse;
      if (afterStart && beforeEnd) verses.add(verse);
    }
  }
  return CrossRefTarget(bookName: name, verses: verses);
});
