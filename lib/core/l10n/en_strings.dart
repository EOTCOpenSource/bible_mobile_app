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
  @override String get welcomeGreeting => 'Welcome Back';

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

  // ── Books tab ─────────────────────────────────────────────────────────────
  @override String get booksTitle          => 'Books';
  @override String get booksOldTestament   => 'Old Testament';
  @override String get booksNewTestament   => 'New Testament';
  @override String booksSubtitle(String c) => '$c Books';
  @override String get booksFilterAll      => 'All';
  @override String get booksFilterLaw      => 'Law';
  @override String get booksFilterHistory  => 'History';
  @override String get booksFilterWisdom   => 'Wisdom';
  @override String get booksFilterProphets => 'Prophets';
  @override String get booksFilterOther    => 'Other';
  @override String get booksFilterGospels    => 'Gospels';
  @override String get booksFilterActs       => 'Acts';
  @override String get booksFilterPauline    => 'Pauline';
  @override String get booksFilterGeneral    => 'General';
  @override String get booksFilterRevelation => 'Revelation';
  @override String get booksChapterSuffix  => 'chs.';

  // ── Reader ────────────────────────────────────────────────────────────────
  @override String get chapterAbbr    => 'Ch';
  @override String get verseBookmark  => 'Bookmark';
  @override String get verseHighlight => 'Highlight';
  @override String get verseCopy      => 'Copy';
  @override String get verseShare     => 'Share';
  @override String get verseMore      => 'More';
  @override String get comingSoon     => 'Coming soon';
}
