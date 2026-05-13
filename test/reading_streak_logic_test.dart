import 'package:flutter_test/flutter_test.dart';

import 'package:bibleflutter/features/books/data/reading_models.dart';
import 'package:bibleflutter/features/books/data/reading_streak_logic.dart';

void main() {
  group('applyStreakAfterQualifyingDay', () {
    test('first ever qualify starts streak at 1', () {
      const prev = ReadingStreakState();
      final next = applyStreakAfterQualifyingDay(
        todayIso: '2026-05-10',
        previous: prev,
      );
      expect(next.lastQualifiedDate, '2026-05-10');
      expect(next.currentStreak, 1);
      expect(next.currentStreakStart, '2026-05-10');
      expect(next.longestStreak, 0);
    });

    test('same day second call is idempotent', () {
      const prev = ReadingStreakState(
        lastQualifiedDate: '2026-05-10',
        currentStreak: 1,
        currentStreakStart: '2026-05-10',
      );
      final next = applyStreakAfterQualifyingDay(
        todayIso: '2026-05-10',
        previous: prev,
      );
      expect(next.lastQualifiedDate, prev.lastQualifiedDate);
      expect(next.currentStreak, prev.currentStreak);
    });

    test('consecutive day increments', () {
      const prev = ReadingStreakState(
        lastQualifiedDate: '2026-05-09',
        currentStreak: 3,
        currentStreakStart: '2026-05-07',
      );
      final next = applyStreakAfterQualifyingDay(
        todayIso: '2026-05-10',
        previous: prev,
      );
      expect(next.currentStreak, 4);
      expect(next.lastQualifiedDate, '2026-05-10');
      expect(next.currentStreakStart, '2026-05-07');
    });

    test('gap breaks streak and updates longest when previous was longer', () {
      const prev = ReadingStreakState(
        lastQualifiedDate: '2026-05-07',
        currentStreak: 5,
        currentStreakStart: '2026-05-03',
        longestStreak: 2,
        longestStreakStart: '2026-01-01',
        longestStreakEnd: '2026-01-02',
      );
      final next = applyStreakAfterQualifyingDay(
        todayIso: '2026-05-10',
        previous: prev,
      );
      expect(next.currentStreak, 1);
      expect(next.currentStreakStart, '2026-05-10');
      expect(next.lastQualifiedDate, '2026-05-10');
      expect(next.longestStreak, 5);
      expect(next.longestStreakStart, '2026-05-03');
      expect(next.longestStreakEnd, '2026-05-07');
    });

    test('gap does not replace longest when previous streak was shorter', () {
      const prev = ReadingStreakState(
        lastQualifiedDate: '2026-05-07',
        currentStreak: 3,
        currentStreakStart: '2026-05-05',
        longestStreak: 10,
        longestStreakStart: '2026-01-01',
        longestStreakEnd: '2026-01-10',
      );
      final next = applyStreakAfterQualifyingDay(
        todayIso: '2026-05-10',
        previous: prev,
      );
      expect(next.longestStreak, 10);
      expect(next.longestStreakStart, '2026-01-01');
      expect(next.longestStreakEnd, '2026-01-10');
      expect(next.currentStreak, 1);
    });
  });
}
