import 'app_strings.dart';

class EnStrings extends AppStrings {
  const EnStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  @override String get navHome   => 'Home';
  @override String get navBooks  => 'Books';
  @override String get navSearch => 'Search';
  @override String get navSaved  => 'Saved';
  @override String get navMe     => 'Me';

  // ── Home header ───────────────────────────────────────────────────────────
  @override String get welcomeGreeting => 'Welcome\nBack';

  // ── Reading streak ────────────────────────────────────────────────────────
  @override String get streakConsecutiveLabel => 'reading streak';
  @override String get streakDaysSuffix       => 'days';
  @override String get streakReadTodayHint    => 'Read a chapter today';
  @override String get streakReadTodayBtn     => 'Read Now';

  /// Sun=0 … Sat=6 one-letter abbreviations.
  @override List<String> get weekdayAbbr => ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // ── Daily verse ───────────────────────────────────────────────────────────
  @override String get dailyVerseTag => 'Daily Verse';

  // ── Continue reading ──────────────────────────────────────────────────────
  @override String get continueReadingTitle          => 'Continue Reading';
  @override String completedPercent(int pct)         => '$pct% complete';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override String get readingPlansTitle => 'Reading Plans';
  @override String get viewAll           => 'View all';
  @override String daysCount(int n)      => '$n days';
}
