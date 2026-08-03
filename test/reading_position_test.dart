import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/features/books/data/reading_models.dart';

void main() {
  group('ReadingPosition & ReadingStreakState deserialization', () {
    test('ReadingPosition.fromRow parses database rows correctly', () {
      final row = {
        'book_id': 'GEN',
        'chapter': 1,
        'verse': 15,
        'updated_at': 1700000000000,
      };

      final pos = ReadingPosition.fromRow(row);
      expect(pos.bookId, 'GEN');
      expect(pos.chapter, 1);
      expect(pos.verse, 15);
      expect(pos.updatedAtMs, 1700000000000);
    });

    test('ReadingPosition.fromRow handles null verse', () {
      final row = {
        'book_id': 'MAT',
        'chapter': 5,
        'verse': null,
        'updated_at': 1700000005000,
      };

      final pos = ReadingPosition.fromRow(row);
      expect(pos.bookId, 'MAT');
      expect(pos.chapter, 5);
      expect(pos.verse, isNull);
    });

    test('ReadingStreakState.fromRow parses DB row and copyWith works', () {
      final row = {
        'last_qualified_date': '2026-05-10',
        'current_streak': 5,
        'current_streak_start': '2026-05-06',
        'longest_streak': 10,
        'longest_streak_start': '2026-01-01',
        'longest_streak_end': '2026-01-10',
      };

      final streak = ReadingStreakState.fromRow(row);
      expect(streak.currentStreak, 5);
      expect(streak.longestStreak, 10);

      final updated = streak.copyWith(currentStreak: 6);
      expect(updated.currentStreak, 6);
      expect(updated.longestStreak, 10);
    });
  });
}
