import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../../../core/storage/app_database_provider.dart';
import '../data/models/book_index_entry.dart';
import '../data/reading_models.dart';
import '../data/reading_progress_repository.dart';

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>(
  (ref) => ReadingProgressRepository(ref.watch(appDatabaseProvider)),
);

/// All books with reading progress, ordered by most recently read.
final continueReadingSnapshotsProvider =
    FutureProvider<List<ContinueReadingSnapshot>>((ref) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  final positions = await repo.getAllReadingPositions();
  if (positions.isEmpty) return [];

  final index = await ref.watch(bibleRepositoryProvider).loadIndex();
  final snapshots = <ContinueReadingSnapshot>[];

  for (final pos in positions) {
    BookIndexEntry? entry;
    for (final e in index) {
      if (e.bookNameEn == pos.bookId) {
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
