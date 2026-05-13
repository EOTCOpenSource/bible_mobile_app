import 'reading_date.dart';
import 'reading_models.dart';

/// Result of applying streak rules after the first qualifying read of [todayIso].
class ApplyStreakResult {
  const ApplyStreakResult({required this.changed, required this.state});

  final bool changed;
  final ReadingStreakState state;
}

/// Advances streak state when the user qualifies **today** for the first time.
///
/// [todayIso] must be `YYYY-MM-DD` for the device-local calendar day.
/// Idempotent when [previous.lastQualifiedDate] already equals [todayIso].
ReadingStreakState applyStreakAfterQualifyingDay({
  required String todayIso,
  required ReadingStreakState previous,
}) =>
    _applyStreakAfterQualifyingDay(todayIso: todayIso, previous: previous).state;

ApplyStreakResult applyStreakAfterQualifyingDayWithChanged({
  required String todayIso,
  required ReadingStreakState previous,
}) =>
    _applyStreakAfterQualifyingDay(todayIso: todayIso, previous: previous);

ApplyStreakResult _applyStreakAfterQualifyingDay({
  required String todayIso,
  required ReadingStreakState previous,
}) {
  if (previous.lastQualifiedDate == todayIso) {
    return ApplyStreakResult(changed: false, state: previous);
  }

  final today = ReadingDate.tryParseIsoDate(todayIso);
  if (today == null) {
    return ApplyStreakResult(changed: false, state: previous);
  }

  final last = ReadingDate.tryParseIsoDate(previous.lastQualifiedDate);
  if (last == null) {
    return ApplyStreakResult(
      changed: true,
      state: ReadingStreakState(
        lastQualifiedDate: todayIso,
        currentStreak: 1,
        currentStreakStart: todayIso,
        longestStreak: previous.longestStreak,
        longestStreakStart: previous.longestStreakStart,
        longestStreakEnd: previous.longestStreakEnd,
      ),
    );
  }

  final gapDays = ReadingDate.calendarDaysBetween(last, today);
  if (gapDays < 0) {
    return ApplyStreakResult(changed: false, state: previous);
  }
  if (gapDays == 0) {
    return ApplyStreakResult(changed: false, state: previous);
  }

  if (gapDays == 1) {
    return ApplyStreakResult(
      changed: true,
      state: ReadingStreakState(
        lastQualifiedDate: todayIso,
        currentStreak: previous.currentStreak + 1,
        currentStreakStart:
            previous.currentStreakStart ?? previous.lastQualifiedDate,
        longestStreak: previous.longestStreak,
        longestStreakStart: previous.longestStreakStart,
        longestStreakEnd: previous.longestStreakEnd,
      ),
    );
  }

  // gapDays > 1 — streak breaks
  var longest = previous.longestStreak;
  var longestStart = previous.longestStreakStart;
  var longestEnd = previous.longestStreakEnd;

  if (previous.currentStreak > longest) {
    longest = previous.currentStreak;
    longestStart = previous.currentStreakStart ?? previous.lastQualifiedDate;
    longestEnd = previous.lastQualifiedDate;
  }

  return ApplyStreakResult(
    changed: true,
    state: ReadingStreakState(
      lastQualifiedDate: todayIso,
      currentStreak: 1,
      currentStreakStart: todayIso,
      longestStreak: longest,
      longestStreakStart: longestStart,
      longestStreakEnd: longestEnd,
    ),
  );
}
