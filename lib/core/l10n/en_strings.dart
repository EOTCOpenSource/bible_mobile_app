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
  @override List<String> get weekdayAbbr      => ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // ── Daily verse ───────────────────────────────────────────────────────────
  @override String get dailyVerseTag => 'Daily Verse';

  // ── Continue reading ──────────────────────────────────────────────────────
  @override String get continueReadingTitle      => 'Continue Reading';
  @override String completedPercent(int pct)     => '$pct% complete';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override String get readingPlansTitle => 'Reading Plans';
  @override String get viewAll           => 'View all';
  @override String daysCount(int n)      => '$n days';

  // ── Me / Settings ─────────────────────────────────────────────────────────
  @override String get meTitle            => 'Settings';
  @override String get meProfileEditBadge => 'Complete Profile';

  @override String get sectionReading   => 'Reading';
  @override String get sectionLanguage  => 'Language';
  @override String get sectionNumbers   => 'Numbers';
  @override String get sectionReminders => 'Reminders';

  @override String get settingTranslation      => 'Default Translation';
  @override String get settingTranslationValue => 'Amharic';
  @override String get settingReadingPrefs     => 'Reading Settings';
  @override String get settingReadingPrefsHint => 'Font, size, theme';
  @override String get settingNightMode        => 'Night Mode';
  @override String get settingNightModeHint    => 'Reduce eye strain';
  @override String get settingAudio            => 'Audio Reading';
  @override String get settingAudioAction      => 'Try';

  @override String get settingLanguage => 'Language';
  @override String get langAmharic     => 'አማርኛ (Amharic)';
  @override String get langEnglish     => 'English';

  @override String get settingGeezNums     => 'Geez Numerals';
  @override String get settingGeezNumsHint => 'Use ፩፪፫ instead of 1 2 3';

  @override String get settingDailyVerse     => 'Daily Verse Notification';
  @override String get settingDailyVerseHint => 'Every morning';
  @override String get settingReadingTime    => 'Reading Time';
  @override String get settingReadingTimeHint => 'Set your daily reading time';
}
