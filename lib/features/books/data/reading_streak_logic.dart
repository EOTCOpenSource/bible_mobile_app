import 'reading_constants.dart';
import 'reading_date.dart';
import 'reading_models.dart';

/// The freeze balance after finishing a day at [streakAfter].
///
/// A freeze lands on every [kFreezeEarnEveryDays]th consecutive day and the
/// balance is capped at [kMaxFreezeCredits], so time away costs the same
/// whether the streak before it was three weeks or three years.
int _creditsAfterDay(int previousCredits, int streakAfter) {
  final earned = streakAfter > 0 && streakAfter % kFreezeEarnEveryDays == 0
      ? 1
      : 0;
  final total = previousCredits + earned;
  return total > kMaxFreezeCredits ? kMaxFreezeCredits : total;
}

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
        freezeCredits: _creditsAfterDay(previous.freezeCredits, 1),
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
    final streak = previous.currentStreak + 1;
    return ApplyStreakResult(
      changed: true,
      state: ReadingStreakState(
        lastQualifiedDate: todayIso,
        currentStreak: streak,
        currentStreakStart:
            previous.currentStreakStart ?? previous.lastQualifiedDate,
        longestStreak: previous.longestStreak,
        longestStreakStart: previous.longestStreakStart,
        longestStreakEnd: previous.longestStreakEnd,
        freezeCredits: _creditsAfterDay(previous.freezeCredits, streak),
      ),
    );
  }

  // The days between the last qualifying read and today, none of them read.
  final missedDays = gapDays - 1;

  // Banked freezes cover the gap: the streak survives but does not grow for the
  // days that were bought — only today counts, so a frozen day is a day kept,
  // never a day earned.
  if (missedDays <= previous.freezeCredits) {
    final streak = previous.currentStreak + 1;
    return ApplyStreakResult(
      changed: true,
      state: ReadingStreakState(
        lastQualifiedDate: todayIso,
        currentStreak: streak,
        currentStreakStart:
            previous.currentStreakStart ?? previous.lastQualifiedDate,
        longestStreak: previous.longestStreak,
        longestStreakStart: previous.longestStreakStart,
        longestStreakEnd: previous.longestStreakEnd,
        freezeCredits:
            _creditsAfterDay(previous.freezeCredits - missedDays, streak),
      ),
    );
  }

  // gapDays > 1 and no freeze to cover it — streak breaks
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
      // Freezes belong to the streak that earned them; the balance that could
      // not save it does not roll over into the next one.
      freezeCredits: 0,
    ),
  );
}
