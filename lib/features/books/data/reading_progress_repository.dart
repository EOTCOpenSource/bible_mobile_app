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
    final isNewChapter =
        await _db.insertChapterReadIfAbsent(bookId: bookId, chapter: chapter);

    // Logged before the streak short-circuit below: the streak row only moves
    // on the first qualifying read of the day, but the calendar needs the day
    // marked whether or not this read was the one that moved it.
    await _db.recordReadDay(today, newChapter: isNewChapter);

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
      freezeCredits: s.freezeCredits,
    );
  }

  Future<ReadingPosition?> getReadingPosition() async {
    final row = await _db.getReadingPositionRow();
    if (row == null) return null;
    return ReadingPosition.fromRow(row);
  }

  Future<List<ReadingPosition>> getAllReadingPositions() async {
    final rows = await _db.getAllReadingPositionRows();
    return rows.map(ReadingPosition.fromRow).toList();
  }

  Future<List<ReadingPosition>> getRecentReadingHistory(int limit) async {
    final rows = await _db.getReadingHistory(limit: limit);
    return rows.map((row) => ReadingPosition(
      bookId: row['book_id'] as String,
      chapter: row['chapter'] as int,
      verse: row['verse'] as int?,
      updatedAtMs: row['opened_at'] as int,
    )).toList();
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

  /// Read days inside `[from, to]`, both ends inclusive, as `YYYY-MM-DD`.
  Future<Set<String>> readDaysBetween(DateTime from, DateTime to) =>
      _db.listReadDaysBetween(
        ReadingDate.toIsoDate(from),
        ReadingDate.toIsoDate(to),
      );

  Future<ReadingTotals> getReadingTotals() async => ReadingTotals(
        totalDays: await _db.countReadDays(),
        totalChapters: await _db.countChaptersRead(),
      );
}
