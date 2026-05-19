import 'app_strings.dart';

class AmStrings extends AppStrings {
  const AmStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  @override
  String get navHome => 'መነሻ';
  @override
  String get navBooks => 'መጽሐፍ';
  @override
  String get navSearch => 'ፈልግ';
  @override
  String get navSaved => 'ስብስቤ';
  @override
  String get navMe => 'እኔ';

  // ── Home header ───────────────────────────────────────────────────────────
  @override
  String get welcomeGreeting => 'እንኳን ደህና መጡ';

  // ── Reading streak ────────────────────────────────────────────────────────
  @override
  String get streakConsecutiveLabel => 'ተከታታይ ንባብ';
  @override
  String get streakDaysSuffix => 'ቀናት';
  @override
  String get streakReadTodayHint => 'ዛሬ ምዕራፍ ያንብቡ';
  @override
  String get streakReadTodayBtn => 'ዛሬ ያንብቡ';
  // ── Daily verse ───────────────────────────────────────────────────────────
  @override
  String get dailyVerseTag => 'የዕለቱ ቃል';

  // ── Continue reading ──────────────────────────────────────────────────────
  @override
  String get continueReadingTitle => 'ንባብ ቀጥል';
  @override
  String completedPercent(int pct) => '$pct% ተጠናቅቋ';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override
  String get readingPlansTitle => 'የንባብ ዕቅዶ';
  @override
  String get viewAll => 'ሁሉንም ይመልከቱ';
  @override
  String daysCount(int n) => '$n ቀናት';

  // ── Me / Settings ─────────────────────────────────────────────────────────
  @override
  String get meTitle => 'ቅንብር';
  @override
  String get meProfileEditBadge => 'ፕሮፋይልን ይስተካከሉ';

  @override
  String get sectionReading => 'ንባብ';
  @override
  String get sectionLanguage => 'ቋንቋ';
  @override
  String get sectionNumbers => 'ቁጥሮች';
  @override
  String get sectionReminders => 'ማሳወቂያ';

  @override
  String get settingTranslation => 'ነባር ትርጉም';
  @override
  String get settingTranslationValue => 'አማርኛ';
  @override
  String get settingReadingPrefs => 'የንባብ ቅንብር';
  @override
  String get settingReadingPrefsHint => 'ፊደሎ፣ መጠን፣ ቀለም';
  @override
  String get settingNightMode => 'ሌሊት ሁነታ';
  @override
  String get settingNightModeHint => 'ዓይን ጉዳት ቀንስ';
  @override
  String get settingAudio => 'ድምፅ ንባብ';
  @override
  String get settingAudioAction => 'ሞክር';

  @override
  String get settingLanguage => 'ቋንቋ';
  @override
  String get langAmharic => 'አማርኛ';
  @override
  String get langEnglish => 'English';

  @override
  String get settingGeezNums => 'የግዕዝ ቁጥሮች';
  @override
  String get settingGeezNumsHint => '፩፪፫ አይነት ቁጥሮችን ተጠቀም';

  @override
  String get settingDailyVerse => 'የዕለቱ ቃል ማሳወቂያ';
  @override
  String get settingDailyVerseHint => 'በየቀኑ ጠዋት';
  @override
  String get settingReadingTime => 'የንባብ ሰዓት';
  @override
  String get settingReadingTimeHint => 'የዕለት ንባብ ሰዓት ምረጥ';

  // ── Books tab ─────────────────────────────────────────────────────────────
  @override
  String get booksTitle => 'መጻሕፍት';
  @override
  String get booksOldTestament => 'ብሉይ ኪዳን';
  @override
  String get booksNewTestament => 'አዲስ ኪዳን';
  @override
  String booksSubtitle(String c) => '$c መጻሕፍት';
  @override
  String get booksFilterAll => 'ሁሉም';
  @override
  String get booksFilterLaw => 'ኦሪት'; // Pentateuch / Torah
  @override
  String get booksFilterHistory => 'ታሪካዊ'; // Historical Books
  @override
  String get booksFilterWisdom => 'ጥበብ'; // Poetry & Wisdom
  @override
  String get booksFilterProphets => 'ነቢያት'; // Prophetic Books
  @override
  String get booksFilterOther => 'ሌሎቹ'; // Other EOTC books
  @override
  String get booksFilterGospels => 'ወንጌሎ';
  @override
  String get booksFilterActs => 'ሐዋሪያ';
  @override
  String get booksFilterPauline => 'ጳውሎስ'; // Pauline Epistles
  @override
  String get booksFilterGeneral => 'ጠቅላላ'; // General Epistles
  @override
  String get booksFilterRevelation => 'ራዕይ'; // Revelation
  @override
  String get booksChapterSuffix => 'ምዕ.';

  // ── Chapter selector ──────────────────────────────────────────────────────
  @override
  String get chapSelectorLastRead => 'ያቆሙበት ቦታ';
  @override
  String get chapSelectorContinueBtn => 'ቀጣይ';
  @override
  String get chapSelectorVerseLabel => 'ቁጥር';
  @override
  String get chapSelectorProgressSuffix => 'የተነበበየተነበበ';
  @override
  String get chapSelectorChapNosLabel => 'ምዕራፍ ቁጥሮ';
  @override
  String get legendCurrent => 'አሁን';
  @override
  String get legendNextChapter => 'ቀጣይ';
  @override
  String get legendUnread => 'ያልተነበበ';
  @override
  String get legendBookmark => 'የተመዘገበ';

  // ── Reading Settings ──────────────────────────────────────────────────────
  @override
  String get readingSettingsTitle => 'የንባብ ቅንብር';
  @override
  String get readingSettingsBodyFont => 'የጽሁፍ ፊደል';
  @override
  String get readingSettingsTitleFont => 'የርዕስ ፊደል';
  @override
  String get readingSettingsFontSize => 'የፊደል መጠን';
  @override
  String get readingSettingsNightMode => 'ሌሊት ሁነታ';
  @override
  String get readingSettingsPreview => 'ቅድመ ዕይታ';
  @override
  String get readingSettingsReset => 'ዳግም ጀምር';
  @override
  String get readingSettingsContinuous => 'ተያያዥ ንባብ';

  // ── Search ───────────────────────────────────────────────────────────────
  @override
  String get searchHint => 'በቅዱሳት መጻሕፍት ፈልግ...';
  @override
  String get searchPrompt => 'ቃሉን ለመፈለግ ይጻፉ';
  @override
  String get searchNoResults => 'ምንም አልተገኘም';
  @override
  String searchResultCount(int n) => '$n ውጤቶ ተገኙ';
  @override
  String get searchRunBtn => 'ፈልግ';
  @override
  String get searchSmartMode => 'Smart';
  @override
  String get searchAllWords => 'ሁሉም ቃላት';
  @override
  String get searchInAll => 'በሁሉም';
  @override
  String get searchScopeTitle => 'ፍለጋ ወሰን';
  @override
  String get searchPickBook => 'መጽሐፍ ምረጥ';
  @override
  String get searchOrPickBook => 'ወይም መጽሐፍ ምረጥ';

  // ── Saved / Collection ───────────────────────────────────────────────────
  @override
  String get savedEyebrow => 'ያቀቡት';
  @override
  String get savedTitle => 'ስብስቤ';
  @override
  String get savedHighlights => 'ምልክቶ';
  @override
  String get savedBookmarks => 'ክታቦ';
  @override
  String get savedNotes => 'ማስታወሻ';
  @override
  String get savedFilterAll => 'ሁሉም';
  @override
  String get savedFilterOld => 'ብሉይ';
  @override
  String get savedFilterNew => 'አዲስ';
  @override
  String get savedPickBook => 'መጽሐፍ ምረጥ';
  @override
  String get savedAllBooks => 'ሁሉም መጻሕፍ';
  @override
  String get savedPickChapter => 'ምዕራፍ ምረጥ';
  @override
  String get savedAllChapters => 'ሁሉም ምዕራፍ';
  @override
  String get savedAllChaptersShort => 'ሁሉም ምዕ.';
  @override
  String savedChapterLabel(int chapter) => 'ምዕ. $chapter';
  @override
  String get savedToday => 'ዛሬ';
  @override
  String get savedYesterday => 'ትናንት';
  @override
  String savedDaysAgo(int days) => '$days ቀን';
  @override
  String get savedEmptyHighlightsTitle => 'ምንም ምልክቶ የለም';
  @override
  String get savedEmptyHighlightsHint => 'ምንባብ ሲያነቡ ቁጥር ጎልቶ ይሰምጡ';
  @override
  String get savedEmptyBookmarksTitle => 'ምንም ክታቦ የለም';
  @override
  String get savedEmptyBookmarksHint => 'ምንባብ ሲያነቡ ቁጥር ያቆዩ';
  @override
  String get savedEmptyNotesTitle => 'ምንም ማስታወሻ የለም';
  @override
  String get savedEmptyNotesHint => 'ምንባብ ሲያነቡ ማስታወሻ ይጻፉ';
  @override
  String get savedEdit => 'አስተካክል';
  @override
  String get savedDelete => 'ሰርዝ';
  @override
  String get savedDeleteNoteTitle => 'ማስታወሻ ሰርዝ';
  @override
  String savedDeleteNoteMessage(String reference) =>
      'ማስታወሻዎን ለመሰረዝ ይፈልጋሉ?\n$reference';
  @override
  String get savedCancel => 'ተወው';
  @override
  String get savedNoteDeleted => 'ማስታወሻ ተሰርዟል';

  // ── Reader ────────────────────────────────────────────────────────────────
  @override
  String get chapterAbbr => 'ምዕ';
  @override
  String get verseBookmark => 'የተመዘገበ';
  @override
  String get verseHighlight => 'ምልክት';
  @override
  String get verseNote => 'ማስታወሻ';
  @override
  String get verseCopy => 'ቅዳ';
  @override
  String get verseShare => 'አጋራ';
  @override
  String get comingSoon => 'በቅርቡ ይመጣል';
}
