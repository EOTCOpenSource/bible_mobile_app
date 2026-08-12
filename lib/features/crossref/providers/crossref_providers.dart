import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bible_repository_provider.dart';
import '../data/models/cross_ref.dart';
import '../data/repositories/crossref_repository.dart';

/// Singleton instance of CrossRefRepository.
final crossRefRepositoryProvider = Provider<CrossRefRepository>((ref) {
  final repository = CrossRefRepository();
  ref.onDispose(repository.clearCache);
  return repository;
});

/// Verse parameter record for looking up cross references.
typedef CrossRefVerseQuery = ({int book, int chapter, int verse});

/// Family provider to retrieve cross references for a verse.
final crossRefsForVerseProvider =
    FutureProvider.family<List<CrossRef>, CrossRefVerseQuery>((ref, query) async {
  final repo = ref.read(crossRefRepositoryProvider);
  return repo.getCrossRefs(query.book, query.chapter, query.verse);
});

/// What one cross-reference row shows: where it points, and the words there.
@immutable
class CrossRefTarget {
  const CrossRefTarget({required this.referenceLabel, this.verseText});

  final String referenceLabel;

  /// Null when the edition does not carry that verse — the row then shows its
  /// reference alone rather than an empty line.
  final String? verseText;
}

/// The book/chapter/verse a row points at, plus the language its label is in.
///
/// The language is part of the key rather than read inside the provider so
/// that switching language produces a different entry instead of a stale one.
typedef CrossRefTargetQuery = ({
  int book,
  int chapter,
  int verse,
  int? toVerse,
  bool amharic,
});

/// Resolves the label and preview text for one cross-reference row.
///
/// A provider rather than a `FutureBuilder` in the row's `build`, because a
/// future created during build is a *new* future on every rebuild: it resolves,
/// calls setState, rebuilds, starts again, and the row's height oscillates
/// between "reference only" and "reference plus preview" forever. That loop is
/// what makes the list jitter in place and never finish loading. Keyed and
/// cached here, each target is resolved once and survives the row scrolling
/// out of view and back.
final crossRefTargetProvider =
    FutureProvider.family<CrossRefTarget, CrossRefTargetQuery>((ref, q) async {
  final repo = ref.read(bibleRepositoryProvider);
  final range = (q.toVerse != null && q.toVerse != q.verse) ? '-${q.toVerse}' : '';

  final entry = await repo.findBook(q.book);
  if (entry == null) {
    // A reference into a book this canon does not carry. The number is still
    // more useful than nothing.
    return CrossRefTarget(
      referenceLabel: 'Book ${q.book} ${q.chapter}:${q.verse}$range',
    );
  }

  final name = q.amharic ? entry.bookNameAm : entry.bookNameEn;
  final label = '$name ${q.chapter}:${q.verse}$range';

  final book = await repo.loadBook(entry);
  for (final chapter in book.chapters) {
    if (chapter.chapterNumber != q.chapter) continue;
    // `allVerses`, not `verses`: a Chapter holds Sections, and the verses hang
    // off those. `chapter.verses` does not exist — it only ever compiled
    // because the repository was reached through a `dynamic`, and threw into a
    // bare catch at runtime, so no row ever showed its preview text.
    for (final verse in chapter.allVerses) {
      if (verse.verseNumber == q.verse) {
        return CrossRefTarget(referenceLabel: label, verseText: verse.text);
      }
    }
    break;
  }
  return CrossRefTarget(referenceLabel: label);
});
