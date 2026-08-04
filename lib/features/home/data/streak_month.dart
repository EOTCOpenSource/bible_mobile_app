import 'package:flutter/foundation.dart';
import 'package:kenat/kenat.dart';

import '../../books/data/reading_date.dart';

/// One cell of the streak calendar: an Ethiopian day and the local date it
/// falls on, so read days (stored as local ISO dates) can be looked up directly.
@immutable
class StreakDay {
  const StreakDay({
    required this.day,
    required this.isoDate,
    required this.isRead,
    required this.isToday,
    required this.isFuture,
  });

  /// Day of the Ethiopian month, 1-based.
  final int day;

  /// The local calendar date this Ethiopian day maps to, `YYYY-MM-DD`.
  final String isoDate;

  final bool isRead;
  final bool isToday;
  final bool isFuture;
}

/// An Ethiopian month laid out for the streak calendar.
@immutable
class StreakMonth {
  const StreakMonth({
    required this.year,
    required this.month,
    required this.name,
    required this.days,
    required this.leadingBlanks,
    required this.weekdayHeaders,
    required this.isCurrentMonth,
  });

  final int year;
  final int month;

  /// Localised month name, e.g. "ሀምሌ".
  final String name;
  final List<StreakDay> days;

  /// Empty cells before day 1 so it sits under its real weekday column.
  final int leadingBlanks;

  /// Column titles, Monday first, matching [leadingBlanks].
  final List<String> weekdayHeaders;

  /// True when this is the month the user is living in — the calendar refuses
  /// to page past it.
  final bool isCurrentMonth;

  int get readCount => days.where((d) => d.isRead).length;
  int get totalDays => days.length;

  /// Days that have already happened, so "18 / 27" measures the month so far
  /// rather than scoring the user against days they have not reached.
  int get elapsedDays => days.where((d) => !d.isFuture).length;

  /// The ISO date of the first day, for querying the read-day log.
  String get firstIso => days.first.isoDate;
  String get lastIso => days.last.isoDate;

  /// The Ethiopian month before this one, rolling the year at ጳጉሜ.
  ({int year, int month}) get previous =>
      month == 1 ? (year: year - 1, month: 13) : (year: year, month: month - 1);

  ({int year, int month}) get next =>
      month == 13 ? (year: year + 1, month: 1) : (year: year, month: month + 1);

  /// Builds an arbitrary Ethiopian month.
  ///
  /// Every cell converts its own Ethiopian day to Gregorian through kenat
  /// rather than counting forward from the first: the Ethiopian year's 13th
  /// month is 5 or 6 days long and leap years shift the mapping, so stepping a
  /// [Duration] across the month drifts off by a day near the boundary.
  factory StreakMonth.of({
    required int year,
    required int month,
    required Set<String> readDays,
    required bool amharic,
  }) {
    final todayIso = ReadingDate.todayIso();
    final todayEt = Kenat.now().getEthiopian();

    final first = Kenat.fromEthiopian(year, month, 1);
    final daysInMonth = first.getDaysInMonth();

    // getWeekday() is 0 = Sunday … 6 = Saturday; the grid runs Monday first.
    final leadingBlanks = (first.getWeekday() + 6) % 7;

    final days = <StreakDay>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final greg = Kenat.fromEthiopian(year, month, d).getGregorian();
      final iso = ReadingDate.toIsoDate(DateTime(
        greg['year'] as int,
        greg['month'] as int,
        greg['day'] as int,
      ));
      days.add(StreakDay(
        day: d,
        isoDate: iso,
        isRead: readDays.contains(iso),
        isToday: iso == todayIso,
        isFuture: iso.compareTo(todayIso) > 0,
      ));
    }

    final monthNames = amharic ? MonthNames.amharic : MonthNames.english;
    final name = month >= 1 && month <= monthNames.length
        ? monthNames[month - 1]
        : '$month';

    // DaysOfWeek is Sunday-first; rotate so Monday leads.
    final dayNames = amharic ? DaysOfWeek.amharic : DaysOfWeek.english;
    final headers = [
      for (var i = 1; i <= 6; i++) dayNames[i],
      dayNames[0],
    ];

    return StreakMonth(
      year: year,
      month: month,
      name: name,
      days: days,
      leadingBlanks: leadingBlanks,
      weekdayHeaders: headers,
      isCurrentMonth:
          year == todayEt['year'] as int && month == todayEt['month'] as int,
    );
  }

  /// The month containing [reference].
  factory StreakMonth.forDate({
    required Kenat reference,
    required Set<String> readDays,
    required bool amharic,
  }) {
    final et = reference.getEthiopian();
    return StreakMonth.of(
      year: et['year'] as int,
      month: et['month'] as int,
      readDays: readDays,
      amharic: amharic,
    );
  }
}
