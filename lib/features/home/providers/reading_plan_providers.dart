import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/storage/app_database_provider.dart';
import '../../../features/books/data/models/book_index_entry.dart';
import '../../../features/books/presentation/pages/reader_screen.dart';
import '../../../core/services/repository_provider.dart';
import '../data/reading_plan.dart';
import '../data/reading_plan_repository.dart';

final readingPlansProvider =
    AsyncNotifierProvider<ReadingPlansNotifier, List<ReadingPlan>>(
  ReadingPlansNotifier.new,
);

class ReadingPlansNotifier extends AsyncNotifier<List<ReadingPlan>> {
  @override
  Future<List<ReadingPlan>> build() async {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated) return [];
    final repo = ReadingPlanRepository(
      ref.read(apiClientProvider),
      authState.token!,
    );
    return repo.fetchPlans();
  }

  Future<void> markDayComplete(String planId, int dayNumber) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) return;
    final repo = ReadingPlanRepository(ref.read(apiClientProvider), token);
    await repo.markDayComplete(planId, dayNumber);
    ref.invalidateSelf();
  }
}

/// Resolves which day/chapter to open for [plan] and navigates to the reader.
/// Saves the position so subsequent taps resume from the same spot.
Future<void> openReadingPlan(
  BuildContext context,
  WidgetRef ref,
  ReadingPlan plan,
) async {
  final db = ref.read(appDatabaseProvider);
  final bibleRepo = BibleRepositoryProvider.of(context);

  // 1. Find the day to open: saved position → first incomplete → first day.
  DailyReading? day;
  final saved = await db.getPlanPosition(plan.id);
  if (saved != null) {
    final savedDay = saved['day_number'] as int;
    day = plan.dailyReadings.cast<DailyReading?>().firstWhere(
          (d) => d!.dayNumber == savedDay,
          orElse: () => null,
        );
  }
  day ??= plan.dailyReadings.cast<DailyReading?>().firstWhere(
        (d) => !d!.isCompleted,
        orElse: () => null,
      );
  day ??= plan.dailyReadings.isNotEmpty ? plan.dailyReadings.first : null;

  if (day == null || day.readings.isEmpty) return;

  // 2. Look up the BookIndexEntry from the first reading's book name.
  // The plan files name books in kebab-case English; resolveBook also accepts
  // canon slugs, Amharic names and USFM ids, so a plan authored against any of
  // those still lands on the right book.
  final reading = day.readings.first;
  final BookIndexEntry? entry = await bibleRepo.resolveBook(reading.book);
  if (entry == null || !context.mounted) return;

  // 3. Save position so next tap resumes here.
  await db.savePlanPosition(
    planId: plan.id,
    dayNumber: day.dayNumber,
    bookId: entry.id,
    chapter: reading.startChapter,
  );

  if (!context.mounted) return;

  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(
        entry: entry,
        initialChapterNumber: reading.startChapter,
      ),
    ),
  );
}
