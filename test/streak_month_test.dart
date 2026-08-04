import 'package:bibleflutter/features/home/data/streak_month.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenat/kenat.dart';

void main() {
  group('StreakMonth', () {
    test('a normal Ethiopian month lays out 30 days', () {
      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 15),
        readDays: const {},
        amharic: true,
      );

      expect(month.month, 11);
      expect(month.year, 2018);
      expect(month.totalDays, 30);
      expect(month.name, MonthNames.amharic[10]);
      expect(month.days.first.day, 1);
      expect(month.days.last.day, 30);
    });

    test('Pagume is short and is not padded out to 30', () {
      // 2018 is not a leap year, so the 13th month runs 5 days.
      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 13, 2),
        readDays: const {},
        amharic: true,
      );

      expect(month.month, 13);
      expect(month.totalDays, 5);
      expect(month.name, MonthNames.amharic[12]);
    });

    test('each day carries the Gregorian date it actually falls on', () {
      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 1),
        readDays: const {},
        amharic: true,
      );

      // Every cell converts independently, so consecutive Ethiopian days must
      // still land on consecutive Gregorian days.
      for (var i = 1; i < month.days.length; i++) {
        final prev = DateTime.parse(month.days[i - 1].isoDate);
        final curr = DateTime.parse(month.days[i].isoDate);
        expect(curr.difference(prev).inDays, 1,
            reason: 'day ${month.days[i].day} broke the run');
      }
    });

    test('read days are matched by their Gregorian ISO date', () {
      final first = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 1),
        readDays: const {},
        amharic: true,
      );
      final thirdIso = first.days[2].isoDate;

      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 1),
        readDays: {thirdIso},
        amharic: true,
      );

      expect(month.readCount, 1);
      expect(month.days[2].isRead, isTrue);
      expect(month.days[1].isRead, isFalse);
      expect(month.days[3].isRead, isFalse);
    });

    test('the English month name is used when not in Amharic', () {
      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 1),
        readDays: const {},
        amharic: false,
      );
      expect(month.name, MonthNames.english[10]);
    });

    test('the query window spans the whole month', () {
      final month = StreakMonth.forDate(
        reference: Kenat.fromEthiopian(2018, 11, 15),
        readDays: const {},
        amharic: true,
      );

      expect(month.firstIso, month.days.first.isoDate);
      expect(month.lastIso, month.days.last.isoDate);
      expect(month.firstIso.compareTo(month.lastIso), lessThan(0));
    });
  });

  group('weekday alignment', () {
    test('day 1 is padded into its real weekday column', () {
      // Hamle 1, 2018 falls on a Wednesday — third column, Monday first.
      final month = StreakMonth.of(
        year: 2018,
        month: 11,
        readDays: const {},
        amharic: true,
      );

      expect(month.leadingBlanks, 2);
    });

    test('every day lands under the header naming its weekday', () {
      final month = StreakMonth.of(
        year: 2018,
        month: 11,
        readDays: const {},
        amharic: false,
      );

      for (var i = 0; i < month.days.length; i++) {
        final column = (month.leadingBlanks + i) % 7;
        final actual = DateTime.parse(month.days[i].isoDate);
        // DateTime.weekday is 1 = Monday, matching a Monday-first grid.
        expect(month.weekdayHeaders[column], DaysOfWeek.english[actual.weekday % 7],
            reason: 'day ${month.days[i].day} sits in the wrong column');
      }
    });

    test('headers run Monday to Sunday', () {
      final month = StreakMonth.of(
        year: 2018,
        month: 11,
        readDays: const {},
        amharic: false,
      );

      expect(month.weekdayHeaders.first, 'Monday');
      expect(month.weekdayHeaders.last, 'Sunday');
      expect(month.weekdayHeaders, hasLength(7));
    });

    test('the pad is never a whole empty row', () {
      for (var m = 1; m <= 13; m++) {
        final month = StreakMonth.of(
          year: 2018,
          month: m,
          readDays: const {},
          amharic: true,
        );
        expect(month.leadingBlanks, inInclusiveRange(0, 6));
      }
    });
  });

  group('month stepping', () {
    test('previous rolls back through Pagume into the prior year', () {
      final meskerem = StreakMonth.of(
        year: 2018,
        month: 1,
        readDays: const {},
        amharic: true,
      );

      expect(meskerem.previous, (year: 2017, month: 13));
    });

    test('next rolls forward out of Pagume into the new year', () {
      final pagume = StreakMonth.of(
        year: 2018,
        month: 13,
        readDays: const {},
        amharic: true,
      );

      expect(pagume.next, (year: 2019, month: 1));
    });

    test('stepping back and forward returns to the same month', () {
      final start = StreakMonth.of(
        year: 2018,
        month: 11,
        readDays: const {},
        amharic: true,
      );
      final back = StreakMonth.of(
        year: start.previous.year,
        month: start.previous.month,
        readDays: const {},
        amharic: true,
      );

      expect(back.next, (year: start.year, month: start.month));
    });

    test('only the month containing today is flagged current', () {
      final todayEt = Kenat.now().getEthiopian();
      final current = StreakMonth.of(
        year: todayEt['year'] as int,
        month: todayEt['month'] as int,
        readDays: const {},
        amharic: true,
      );
      expect(current.isCurrentMonth, isTrue);

      final earlier = StreakMonth.of(
        year: current.previous.year,
        month: current.previous.month,
        readDays: const {},
        amharic: true,
      );
      expect(earlier.isCurrentMonth, isFalse);
    });
  });

  group('elapsed days', () {
    test('a past month counts every one of its days', () {
      // Far enough back that nothing in it is in the future.
      final month = StreakMonth.of(
        year: 2015,
        month: 5,
        readDays: const {},
        amharic: true,
      );

      expect(month.elapsedDays, month.totalDays);
      expect(month.days.every((d) => !d.isFuture), isTrue);
    });

    test('the current month stops counting at today', () {
      final todayEt = Kenat.now().getEthiopian();
      final month = StreakMonth.of(
        year: todayEt['year'] as int,
        month: todayEt['month'] as int,
        readDays: const {},
        amharic: true,
      );

      expect(month.elapsedDays, todayEt['day'] as int);
      expect(month.elapsedDays, lessThanOrEqualTo(month.totalDays));
    });
  });
}
