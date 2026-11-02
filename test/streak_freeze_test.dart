import 'package:bibleflutter/features/books/data/reading_constants.dart';
import 'package:bibleflutter/features/books/data/reading_models.dart';
import 'package:bibleflutter/features/books/data/reading_streak_logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads on every day from [from] to [to] inclusive, starting from [initial].
ReadingStreakState _readEveryDayThrough(
  int days, {
  ReadingStreakState initial = const ReadingStreakState(),
}) {
  var state = initial;
  for (var i = 0; i < days; i++) {
    final day = DateTime(2026, 1, 1).add(Duration(days: i));
    final iso = '${day.year}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    state = applyStreakAfterQualifyingDay(todayIso: iso, previous: state);
  }
  return state;
}

void main() {
  group('freeze credits are earned', () {
    test('a week of reading banks exactly one', () {
      final state = _readEveryDayThrough(kFreezeEarnEveryDays);
      expect(state.currentStreak, kFreezeEarnEveryDays);
      expect(state.freezeCredits, 1);
    });

    test('none before the week is complete', () {
      final state = _readEveryDayThrough(kFreezeEarnEveryDays - 1);
      expect(state.freezeCredits, 0);
    });

    test('the balance stops at the cap', () {
      // Long enough to earn more than the cap allows.
      final state =
          _readEveryDayThrough(kFreezeEarnEveryDays * (kMaxFreezeCredits + 3));
      expect(state.freezeCredits, kMaxFreezeCredits);
    });
  });

  group('freeze credits are spent', () {
    test('one missed day is bridged and the streak keeps growing', () {
      // 7 days ending 2026-01-07, one freeze banked.
      final before = _readEveryDayThrough(7);
      expect(before.lastQualifiedDate, '2026-01-07');
      expect(before.freezeCredits, 1);

      // Nothing on the 8th; back on the 9th.
      final after = applyStreakAfterQualifyingDay(
        todayIso: '2026-01-09',
        previous: before,
      );

      expect(after.currentStreak, 8, reason: 'survives, counting only the 9th');
      expect(after.currentStreakStart, before.currentStreakStart);
      expect(after.freezeCredits, 0, reason: 'the banked day paid for the gap');
    });

    test('a gap wider than the balance still breaks the streak', () {
      final before = _readEveryDayThrough(7);
      expect(before.freezeCredits, 1);

      // Two missed days against a balance of one.
      final after = applyStreakAfterQualifyingDay(
        todayIso: '2026-01-10',
        previous: before,
      );

      expect(after.currentStreak, 1);
      expect(after.longestStreak, 7);
      expect(after.freezeCredits, 0);
    });

    test('two banked days bridge two missed days', () {
      final before = _readEveryDayThrough(kFreezeEarnEveryDays * 2);
      expect(before.freezeCredits, 2);
      expect(before.lastQualifiedDate, '2026-01-14');

      final after = applyStreakAfterQualifyingDay(
        todayIso: '2026-01-17', // 15th and 16th missed
        previous: before,
      );

      expect(after.currentStreak, 15);
      expect(after.freezeCredits, 0);
    });

    test('a broken streak does not carry its credits into the next one', () {
      final before = _readEveryDayThrough(kFreezeEarnEveryDays * 2);
      expect(before.freezeCredits, kMaxFreezeCredits);

      // A week away — far past what the balance can cover.
      final after = applyStreakAfterQualifyingDay(
        todayIso: '2026-01-25',
        previous: before,
      );

      expect(after.currentStreak, 1);
      expect(after.freezeCredits, 0);
    });
  });

  test('a bridged day does not count toward the next freeze', () {
    // 7 days → 1 credit. Skip a day, spend it, then read up to day 14 of the
    // streak: crossing 14 earns the next one.
    var state = _readEveryDayThrough(7);
    state = applyStreakAfterQualifyingDay(
      todayIso: '2026-01-09',
      previous: state,
    );
    expect(state.currentStreak, 8);
    expect(state.freezeCredits, 0);

    for (var d = 10; d <= 15; d++) {
      state = applyStreakAfterQualifyingDay(
        todayIso: '2026-01-${d.toString().padLeft(2, '0')}',
        previous: state,
      );
    }

    expect(state.currentStreak, 14);
    expect(state.freezeCredits, 1);
  });
}
