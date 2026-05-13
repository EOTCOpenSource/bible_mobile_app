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

/// Resolves [reading_position] against the loaded Bible index.
final continueReadingSnapshotProvider =
    FutureProvider<ContinueReadingSnapshot?>((ref) async {
  final pos = await ref.watch(readingProgressRepositoryProvider).getReadingPosition();
  if (pos == null) return null;

  final index = await ref.watch(bibleRepositoryProvider).loadIndex();
  BookIndexEntry? entry;
  for (final e in index) {
    if (e.bookNameEn == pos.bookId) {
      entry = e;
      break;
    }
  }
  if (entry == null) return null;

  final readCount =
      await ref.watch(readingProgressRepositoryProvider).countChaptersReadForBook(pos.bookId);
  final total = entry.chapterCount ?? 1;

  return ContinueReadingSnapshot(
    entry: entry,
    position: pos,
    chaptersReadInBook: readCount,
    totalChapters: total,
  );
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
