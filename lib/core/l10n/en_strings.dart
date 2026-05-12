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

  // ── Chapter selector ──────────────────────────────────────────────────────
  @override String get chapSelectorLastRead       => 'Where you left off';
  @override String get chapSelectorContinueBtn    => 'Continue';
  @override String get chapSelectorVerseLabel     => 'Vs';
  @override String get chapSelectorProgressSuffix => 'read';
  @override String get chapSelectorChapNosLabel   => 'Chapter Nos.';
  @override String get legendCurrent              => 'Now';
  @override String get legendUnread               => 'Unread';
  @override String get legendBookmark             => 'Bookmarked';

  // ── Reading Settings ──────────────────────────────────────────────────────
  @override String get readingSettingsTitle     => 'Reading Settings';
  @override String get readingSettingsBodyFont  => 'Body Font';
  @override String get readingSettingsTitleFont => 'Title Font';
  @override String get readingSettingsFontSize  => 'Font Size';
  @override String get readingSettingsNightMode => 'Night Mode';
  @override String get readingSettingsPreview   => 'Preview';
  @override String get readingSettingsReset     => 'Reset';

  // ── Search ───────────────────────────────────────────────────────────────
  @override String get searchHint         => 'Search the scriptures...';
  @override String get searchPrompt       => 'Type to search';
  @override String get searchNoResults    => 'No results found';
  @override String searchResultCount(int n) => '$n result${n == 1 ? '' : 's'}';
  @override String get searchRunBtn       => 'Go';
  @override String get searchSmartMode    => 'Smart';
  @override String get searchAllWords     => 'All Words';
  @override String get searchInAll        => 'In All';
@override String get searchScopeTitle   => 'Search Scope';
  @override String get searchPickBook     => 'Pick a Book';
  @override String get searchOrPickBook   => 'Or pick a book';

  // ── Reader ────────────────────────────────────────────────────────────────
  @override String get chapterAbbr    => 'Ch';
  @override String get verseBookmark  => 'Bookmark';
  @override String get verseHighlight => 'Highlight';
  @override String get verseCopy      => 'Copy';
  @override String get verseShare     => 'Share';
  @override String get verseMore      => 'More';
  @override String get comingSoon     => 'Coming soon';
}
