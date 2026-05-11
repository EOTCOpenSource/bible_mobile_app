import 'app_strings.dart';

class AmStrings extends AppStrings {
  const AmStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  @override String get navHome   => 'መነሻ';
  @override String get navBooks  => 'መጽሐፍ';
  @override String get navSearch => 'ፈልግ';
  @override String get navSaved  => 'ተቀምጠ';
  @override String get navMe     => 'እኔ';

  // ── Home header ───────────────────────────────────────────────────────────
  @override String get welcomeGreeting => 'እንኳን ደህና\nመጡ';

  // ── Reading streak ────────────────────────────────────────────────────────
  @override String get streakConsecutiveLabel => 'ተከታታይ ንባብ';
  @override String get streakDaysSuffix       => 'ቀናት';
  @override String get streakReadTodayHint    => 'ዛሬ ምዕራፍ ያንብቡ';
  @override String get streakReadTodayBtn     => 'ዛሬ ያንብቡ';

  /// Sun=0 … Sat=6 abbreviations in Ethiopic script.
  @override List<String> get weekdayAbbr => ['እ', 'ሰ', 'ሠ', 'ረ', 'ሐ', 'ዓ', 'ቅ'];

  // ── Daily verse ───────────────────────────────────────────────────────────
  @override String get dailyVerseTag => 'የዕለቱ ቃል';

  // ── Continue reading ──────────────────────────────────────────────────────
  @override String get continueReadingTitle          => 'ንባብ ቀጥል';
  @override String completedPercent(int pct)         => '$pct% ተጠናቅቋ';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override String get readingPlansTitle => 'የንባብ ዕቅዶ';
  @override String get viewAll           => 'ሁሉንም ይመልከቱ';
  @override String daysCount(int n)      => '$n ቀናት';
}
