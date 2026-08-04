import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../../../core/storage/app_database_provider.dart';
import '../data/models/book_index_entry.dart';
import '../data/reading_date.dart';
import '../data/reading_models.dart';
import '../data/reading_progress_repository.dart';

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>(
  (ref) => ReadingProgressRepository(ref.watch(appDatabaseProvider)),
);

/// All books with reading progress, ordered by most recently read.
final continueReadingSnapshotsProvider =
    FutureProvider<List<ContinueReadingSnapshot>>((ref) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  var positions = await repo.getRecentReadingHistory(5);
  if (positions.isEmpty) {
    positions = (await repo.getAllReadingPositions()).take(5).toList();
  }
  if (positions.isEmpty) return [];

  final index = await ref.watch(bibleRepositoryProvider).loadIndex();
  final snapshots = <ContinueReadingSnapshot>[];

  for (final pos in positions) {
    BookIndexEntry? entry;
    for (final e in index) {
      if (e.id == pos.bookId) {
        entry = e;
        break;
      }
    }
    if (entry == null) continue;

    final readCount = await repo.countChaptersReadForBook(pos.bookId);
    final total = entry.chapterCount ?? 1;

    snapshots.add(ContinueReadingSnapshot(
      entry: entry,
      position: pos,
      chaptersReadInBook: readCount,
      totalChapters: total,
    ));
  }

  return snapshots;
});

final readingStreakStateProvider = FutureProvider<ReadingStreakState>((ref) async {
  return ref.watch(readingProgressRepositoryProvider).getReadingStreakState();
});

final readingTotalsProvider = FutureProvider<ReadingTotals>((ref) async {
  return ref.watch(readingProgressRepositoryProvider).getReadingTotals();
});

/// Read days inside a half-open window, keyed by its two ISO endpoints.
///
/// Keyed on strings rather than [DateTime] so the family caches: two
/// [DateTime]s for the same day are not `==` unless both are already
/// midnight-normalised, and a miss here refetches the whole calendar.
final readDaysInRangeProvider =
    FutureProvider.family<Set<String>, ({String from, String to})>(
        (ref, range) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  final from = ReadingDate.tryParseIsoDate(range.from);
  final to = ReadingDate.tryParseIsoDate(range.to);
  if (from == null || to == null) return const <String>{};
  return repo.readDaysBetween(from, to);
});

@immutable
class ContinueReadingSnapshot {
  const ContinueReadingSnapshot({
    required this.entry,
    required this.position,
    required this.chaptersReadInBook,
    required this.totalChapters,
  });

  final BookIndexEntry entry;
  final ReadingPosition position;
  final int chaptersReadInBook;
  final int totalChapters;

  int get progressPercent {
    if (totalChapters <= 0) return 0;
    return ((chaptersReadInBook / totalChapters) * 100).round().clamp(0, 100);
  }
}
