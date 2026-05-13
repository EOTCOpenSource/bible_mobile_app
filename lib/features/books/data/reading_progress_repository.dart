import '../../../core/storage/app_database.dart';
import 'reading_date.dart';
import 'reading_models.dart';
import 'reading_streak_logic.dart';

class ReadingProgressRepository {
  ReadingProgressRepository(this._db);

  final AppDatabase _db;

  Future<void> saveReadingPosition({
    required String bookId,
    required int chapter,
    int? verse,
  }) =>
      _db.upsertReadingPosition(bookId: bookId, chapter: chapter, verse: verse);

  /// Marks [chapter] as read for progress (idempotent) and updates the streak
  /// row only on the **first** qualifying event of [todayIso].
  Future<void> recordQualifiedChapterRead({
    required String bookId,
    required int chapter,
    String? todayIso,
  }) async {
    final today = todayIso ?? ReadingDate.todayIso();
    await _db.insertChapterReadIfAbsent(bookId: bookId, chapter: chapter);

    final row = await _db.getReadingStreakRow();
    final prev = ReadingStreakState.fromRow(row);
    if (prev.lastQualifiedDate == today) return;

    final result = applyStreakAfterQualifyingDayWithChanged(
      todayIso: today,
      previous: prev,
    );
    if (!result.changed) return;

    final s = result.state;
    await _db.updateReadingStreakRow(
      lastQualifiedDate: s.lastQualifiedDate,
      currentStreak: s.currentStreak,
      currentStreakStart: s.currentStreakStart,
      longestStreak: s.longestStreak,
      longestStreakStart: s.longestStreakStart,
      longestStreakEnd: s.longestStreakEnd,
    );
  }

  Future<ReadingPosition?> getReadingPosition() async {
    final row = await _db.getReadingPositionRow();
    if (row == null) return null;
    return ReadingPosition.fromRow(row);
  }

  Future<ReadingStreakState> getReadingStreakState() async {
    final row = await _db.getReadingStreakRow();
    return ReadingStreakState.fromRow(row);
  }

  Future<int> countChaptersReadForBook(String bookId) =>
      _db.countChaptersReadForBook(bookId);

  Future<Set<int>> readChapterNumbersForBook(String bookId) async {
    final list = await _db.listReadChaptersForBook(bookId);
    return list.toSet();
  }
}
