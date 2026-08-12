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
  String get navPlans => 'እቅዶች';
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

  // ── Streak emoji customisation ────────────────────────────────────────────
  @override
  String get streakEmojiTitle => 'የተከታታይ ንባብ ምልክት';
  @override
  String get streakEmojiHint => 'ከንባብ ቀኖችዎ ጎን የሚታየው ምልክት';
  @override
  String get streakEmojiSectionChoose => 'ምልክት ይምረጡ';
  @override
  String get streakEmojiPreviewLabel => 'ቅድመ እይታ';
  @override
  String get streakEmojiWidgetNote =>
      'የመረጡት ምልክት በመተግበሪያው ውስጥ ካሉት የተከታታይ ንባብ ገጾች ጎንም ይታያል።';

  // ── Home screen widgets ───────────────────────────────────────────────────
  @override
  String get sectionWidgets => 'መግብሮች';
  @override
  String get widgetsTitle => 'የመነሻ ገጽ መግብሮች';
  @override
  String get widgetsHint => 'ገጽታ፣ የጽሑፍ መጠንና የሚታዩ ክፍሎችን ያብጁ';
  @override
  String get widgetsChooseLabel => 'መግብር ይምረጡ';

  @override
  String get widgetNameDailyVerse => 'የዕለቱ ቃል';
  @override
  String get widgetNameContinue => 'ንባብ ቀጥል';
  @override
  String get widgetNameStreak => 'ተከታታይ ንባብ';

  @override
  String get widgetSectionTheme => 'ገጽታ';
  @override
  String get widgetThemeAuto => 'ራስ-ሰር';
  @override
  String get widgetThemeLight => 'ብሩህ';
  @override
  String get widgetThemeDark => 'ጨለማ';
  @override
  String get widgetThemeBrand => 'ወይን ጠጅ';

  @override
  String get widgetSectionTextSize => 'የጽሑፍ መጠን';
  @override
  String get widgetTextSmall => 'ትንሽ';
  @override
  String get widgetTextMedium => 'መካከለኛ';
  @override
  String get widgetTextLarge => 'ትልቅ';

  @override
  String get widgetSectionOpacity => 'የጀርባ ግልጽነት';
  @override
  String get widgetSectionOptions => 'የሚታዩ ክፍሎች';

  @override
  String get widgetToggleVerseTag => 'የላይኛው መለያ';
  @override
  String get widgetToggleVerseRef => 'የጥቅስ ማጣቀሻ';
  @override
  String get widgetToggleContinueLabel => 'መለያ';
  @override
  String get widgetToggleProgressBar => 'የእድገት መስመር';
  @override
  String get widgetToggleStreakDays => 'የቀናት መለያ';
  @override
  String get widgetToggleStreakEmoji => 'ምልክት';

  @override
  String get widgetEmptyVerse => 'መተግበሪያውን ይክፈቱ';
  @override
  String get widgetEmptyContinue => 'ንባብ ይጀምሩ';

  @override
  String get widgetAddToHome => 'ወደ መነሻ ገጽ ጨምር';
  @override
  String get widgetAddUnsupported =>
      'ማስጀመሪያዎ ይህን አይፈቅድም። መነሻ ገጽዎን ተጭነው በመያዝ መግብሩን ያክሉ።';
  @override
  String get widgetResizeHint =>
      'መግብሩን በመነሻ ገጽ ላይ ተጭነው በመያዝ መጠኑን መቀየር ይችላሉ፤ ይዘቱ ከመጠኑ ጋር ይስተካከላል።';
  @override
  String get widgetsAndroidOnly => 'የመነሻ ገጽ መግብሮች በአንድሮይድ ላይ ብቻ ይገኛሉ።';

  // ── Streak page ───────────────────────────────────────────────────────────
  @override
  String get streakPageTitle => 'ተከታታይ ንባብ';
  @override
  String get streakDayStreakLabel => 'ተከታታይ ቀናት';
  @override
  String get streakStatLongest => 'ረጅሙ ተከታታይ';
  @override
  String get streakStatTotalDays => 'ጠቅላላ ቀናት';
  @override
  String get streakStatChapters => 'ምዕራፎች';
  @override
  String streakMonthProgress(String read, String total) =>
      '$read / $total ቀናት';
  @override
  String streakFreezeTitle(String count) => '$count የእረፍት ቀን አለዎት';
  @override
  String get streakFreezeSubtitle => 'ንባብ ባያደርጉ ተከታታይዎ ይጠበቃል';
  @override
  String get streakFreezeEmptyTitle => 'የእረፍት ቀን የለዎትም';
  @override
  String get streakFreezeEmptySubtitle => 'በየሳምንቱ ንባብ አንድ የእረፍት ቀን ያስገኛል';
  @override
  String get streakTodayDone => 'ዛሬ ተነቧል';

  // ── Daily verse ───────────────────────────────────────────────────────────
  @override
  String get dailyVerseTag => 'የዕለቱ ቃል';
  @override
  String get dailyVerseUnavailable => 'የዕለቱ ቃል መጫን አልተቻለም። እንደገና ይሞክሩ።';

  // ── Continue reading ──────────────────────────────────────────────────────
  @override
  String get continueReadingTitle => 'ንባብ ቀጥል';
  @override
  String get startReadingTitle => 'ንባብ ይጀምሩ';
  @override
  String get startReadingAction => 'ጀምር';
  @override
  String completedPercent(int pct) => '$pct% ተጠናቅቋ';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override
  String get readingPlansTitle => 'የንባብ ዕቅዶ';
  @override
  String get viewAll => 'ሁሉንም ይመልከቱ';
  @override
  String daysCount(int n) => '$n ቀናት';
  @override
  String get readingPlansSyncPrompt => 'የንባብ ዕቅዶዎን በሁሉም መሣሪያዎች ለማስተባበር ይግቡ';
  @override
  String get continueWithoutAccount => 'ያለ መለያ ቀጥል';

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
  String get booksDeuterocanonical => 'ዲዩትሮካኖኒካል';
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

  // ── Book Introductions ──────────────────────────────────────────────────
  @override
  String get aboutThisBook => 'ስለዚህ መጽሐፍ';
  @override
  String get author => 'ደራሲ';
  @override
  String get period => 'ዘመን';
  @override
  String get themes => 'ርዕሶች';
  @override
  String get readMore => 'ተጨማሪ አንብብ';
  @override
  String get showLess => 'በትንሹ አሳይ';
  @override
  String get outline => 'አብነት';

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
  @override
  String get readingSettingsLineHeight => 'የረድፍ ክፍተት';
  @override
  String get readingSettingsMarginScale => 'የጎን ህዳግ';
  @override
  String get readingSettingsTextAlign => 'የጽሑፍ አሰላለፍ';
  @override
  String get readingSettingsAlignStart => 'በስተግራ';
  @override
  String get readingSettingsAlignJustify => 'የተመጣጠነ';
  @override
  String get readingSettingsKeepScreenOn => 'ስክሪን እንዳይጠፋ';
  @override
  String get readingSettingsShowCrossRefMarkers => 'የማጣቀሻ ምልክቶችን አሳይ';
  @override
  String get readingSettingsShowCrossRefMarkersHint => 'በጥቅሶች ላይ የማጣቀሻ ምልክት ያሳያል';

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
  String get savedTitle => 'የተቀመጡ';
  @override
  String get savedHistory => 'ታሪክ';
  @override
  String get savedHighlights => 'ማድመቂያዎች';
  @override
  String get savedBookmarks => 'ዕልባቶች';
  @override
  String get savedNotes => 'ማስታወሻዎች';
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
  String get savedEmptyNotesHint => 'አንድን ጥቅስ ሲመርጡ "ማስታወሻ" የሚለውን በመጫን ሃሳብዎን መመዝገብ ይችላሉ። ማስታወሻዎችዎ እዚህ ይዘረዘራሉ።';
  @override
  String get savedClearHistory => 'ታሪክ አጽዳ';
  @override
  String get savedClearHistoryTitle => 'የንባብ ታሪክን ያጽዱ?';
  @override
  String get savedClearHistoryMessage => 'ይህ እርምጃ የንባብ ታሪክዎን ይሰርዛል፤ ሊቀለበስ አይችልም።';
  @override
  String get savedEdit => 'አርትዕ';
  @override
  String get savedDelete => 'ሰርዝ';
  @override
  String get savedDeleteNoteTitle => 'ማስታወሻ ሰርዝ';
  @override
  String savedDeleteNoteMessage(String reference) =>
      'ማስታወሻዎን ለመሰረዝ ይፈልጋሉ?\n$reference';
  @override
  String get savedDeleteBookmarkTitle => 'ክታቦ ሰርዝ';
  @override
  String savedDeleteBookmarkMessage(String reference) =>
      'ክታቦዎን ለመሰረዝ ይፈልጋሉ?\n$reference';
  @override
  String get savedDeleteHighlightTitle => 'ምልክቶ ሰርዝ';
  @override
  String savedDeleteHighlightMessage(String reference) =>
      'ምልክቶዎን ለመሰረዝ ይፈልጋሉ?\n$reference';
  @override
  String get savedCancel => 'ተወው';
  @override
  String get savedNoteDeleted => 'ማስታወሻ ተሰርዟል';
  @override
  String get savedBookmarkDeleted => 'ክታቦ ተሰርዟል';
  @override
  String get savedHighlightDeleted => 'ምልክቶ ተሰርዟል';
  @override
  String get timeMorning => 'ጠዋት';
  @override
  String get timeAfternoon => 'ከሰዓት';
  @override
  String get historyEmptyHint => 'ንባብ ሲጀምሩ ታሪክዎ እዚህ ይታያል';
  @override
  String get loadMore => 'ተጨማሪ አሳይ';
  @override
  String get savedDeleteHistoryTitle => 'ይህን መዝገብ ከታሪክ ያጥፋ?';
  @override
  String get collections => 'ስብስቦች';
  @override
  String get newCollection => 'አዲስ ስብስብ';
  @override
  String get addToCollection => 'ወደ ስብስብ ጨምር';
  @override
  String get collectionSubtitle =>
      'ይህንን ንጥል በአንድ ወይም ከዚያ በላይ በሆኑ ስብስቦች ውስጥ ያደራጁ።';
  @override
  String get collectionSearchHint => 'ስብስብ ይፈልጉ ወይም ይፍጠሩ...';
  @override
  String createNamedCollection(String name) => '"$name" ፍጠር';
  @override
  String get recentCollections => 'የቅርብ ጊዜ ስብስቦች';
  @override
  String get allCollections => 'ሁሉም ስብስቦች';
  @override
  String get noCollectionsEmptyHint =>
      'የመጀመሪያዎን ስብስብ ለመፍጠር መተየብ ይጀምሩ።';
  @override
  String get noCollectionsFound => 'ምንም ስብስቦች አልተገኙም';
  @override
  String get tags => 'መለያዎች';
  @override
  String get addTags => 'መለያ ጨምር';
  @override
  String get all => 'ሁሉም';
  @override
  String get noCollections => 'እስካሁን ስብስብ የለም';
  @override
  String get addTagHint => 'መለያ ያስገቡ (ኮማ ወይም Enter ይጫኑ)...';
  @override
  String get collectionNameHint => 'የስብስብ ስም';
  @override
  String get collectionColorLabel => 'ቀለም';
  @override
  String get collectionCreateAction => 'ፍጠር';
  @override
  String get savedOk => 'እሺ';
  @override
  String get collectionDeleteTitle => 'ስብስብ ሰርዝ';
  @override
  String get collectionDeleteMessage =>
      'ይህ ስብስብ ይሰረዛል። በውስጡ ያሉት ማስታወሻዎች፣ ማድመቂያዎችና ዕልባቶች አይሰረዙም።';
  @override
  String selectedCount(int count) => '$count ተመርጠዋል';
  @override
  String get deleteSelectedTitle => 'የተመረጡትን ሰርዝ';
  @override
  String deleteSelectedMessage(int count) =>
      'እርግጠኛ ነዎት $count የተመረጡትን ንጥሎች መሰረዝ ይፈልጋሉ?';

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
  String get verseCrossReferences => 'ተመሳሳይ ጥቅሶች';
  @override
  String get crossRefTitle => 'የጽሑፍ ማጣቀሻዎች';
  @override
  String get crossRefNoResults => 'ለዚህ ጥቅስ ምንም ማጣቀሻ አልተገኘም';
  @override
  String crossRefBackTo(String reference) => '← ወደ $reference ተመለስ';
  @override
  String get verseFootnotes => 'የትርጉም ማስታወሻ';
  @override
  String get comingSoon => 'በቅርቡ ይመጣል';

  // ── Auth — shared ─────────────────────────────────────────────────────────
  @override
  String get authEmail => 'ኢሜል';
  @override
  String get authEmailRequired => 'ኢሜል ያስፈልጋል';
  @override
  String get authEmailInvalid => 'ትክክለኛ ኢሜል ያስገቡ';
  @override
  String get authPassword => 'የይለፍ ቃል';
  @override
  String get authPasswordRequired => 'የይለፍ ቃል ያስፈልጋል';
  @override
  String get authConnectionError => 'ግንኙነት አልተሳካም። ድጋሚ ይሞክሩ።';

  // ── Auth — login ──────────────────────────────────────────────────────────
  @override
  String get loginTitle => 'እንኳን ደህና መጡ';
  @override
  String get loginSubtitle => 'መጽሐፍ ቅዱስ ማንበብ ለመቀጠል ይግቡ።';
  @override
  String get loginRememberMe => 'አስታወስኝ';
  @override
  String get loginForgotPassword => 'የይለፍ ቃል ረሳህ?';
  @override
  String get loginButton => 'ግባ';
  @override
  String get loginOrDivider => 'ወይም በነዚህ ይግቡ';
  @override
  String get loginNoAccount => 'አካውንት የለዎትም? ';
  @override
  String get loginRegisterLink => 'ይ​መዝ​ገቡ';
  @override
  String get loginVerseQuote => 'ቃልህ ለመንገዴ ብርሃን ነው';
  @override
  String get loginAccountLocked => 'መለያዎ ተቆልፏል። ከ2 ሰዓት በኋላ ይሞክሩ።';
  @override
  String get loginGoogleFailed => 'Google ግባ አልተሳካም። ድጋሚ ይሞክሩ።';
  @override
  String get loginFacebookComingSoon => 'Facebook Sign In — በቅርብ ይመጣል';

  // ── Auth — register ───────────────────────────────────────────────────────
  @override
  String get registerTitle => 'አካውንት ይፍጠሩ';
  @override
  String get registerSubtitle => 'የ ንባብ ሂደቶን፣ ኖቶቹን፣ እና ቀለሞችን ';
  @override
  String get registerFullName => 'ሙሉ ስም';
  @override
  String get registerFullNameRequired => 'ሙሉ ስም ያስፈልጋል';
  @override
  String get registerFullNameTooShort => 'ስም ቢያንስ 2 ፊደላት ያስፈልጋሉ';
  @override
  String get registerPasswordTooShort => 'ቢያንስ 8 ቁምፊዎች ያስፈልጋሉ';
  @override
  String get registerAcceptTerms => 'ውሎቹን እና ሁኔታዎቹን ይቀበሉ';
  @override
  String get registerButton => 'ይ​መዝ​ጋቡ';
  @override
  String get registerHaveAccount => 'መለያ አለዎት? ';
  @override
  String get registerLoginLink => 'ይ​ግቡ';
  @override
  String get registerTermsText =>
      'I accept the Community Terms and Privacy Policy.';
  @override
  String get passwordWeak => 'ደካማ';
  @override
  String get passwordFair => 'መካከለኛ';
  @override
  String get passwordGood => 'ጥሩ';
  @override
  String get passwordStrong => 'ጠንካራ';

  // ── Auth — OTP ────────────────────────────────────────────────────────────
  @override
  String get otpTitle => 'ኮድዎን ያረጋግጡ';
  @override
  String get otpSentPrefix => 'ወደ ';
  @override
  String get otpSentSuffix => ' 6 አሃዝ ኮድ ልከናል። አባክዎ ከታች ያስገቡ።';
  @override
  String otpDigitsRequired(int n) => 'የ$n ቁጥር ኮድ ያስፈልጋል';
  @override
  String get otpNotReceived => 'ኮድ አልደረሰዎትም? ';
  @override
  String otpResendIn(String t) => 'ድጋሚ ላክ $t';
  @override
  String get otpResend => 'ድጋሚ ላክ';
  @override
  String get otpVerifyButton => 'አረጋጥ';
  @override
  String get otpChangePhone => 'ስልክ ቁጥር ለውጥ';
  @override
  String get otpChangeEmail => 'ኢሜል ለውጥ';
  @override
  String get otpResendFailed => 'ኮድ መላክ አልተሳካም። ድጋሚ ይሞክሩ።';

  // ── Forgot password ───────────────────────────────────────────────────────
  @override
  String get forgotTitle => 'የይለፍ ቃል ረሱ?';
  @override
  String get forgotSubtitle =>
      'ምንም አያስቡ። የተመዘገቡበትን ኢሜልዎን ያስገቡ፤ የዳግም ማስጀመሪያ ኮድ እንልካለን።';
  @override
  String get forgotEmailLabel => 'የተመዘገቡበት ኢሜል';
  @override
  String get forgotEmailHelper => 'የዳግም ማስጀመሪያ ኮዱ ወደዚህ ኢሜል ይላካል።';
  @override
  String get forgotPhoneLabel => 'የተመዘገቡ ስልክ ቁጥር';
  @override
  String get forgotPhoneHelper => 'የዳግም ማስጀመሪያ ኮዱ ወደዚህ ስልክ ቁጥር ይላካል።';
  @override
  String get forgotSendButton => 'ኮድ ላክ';
  @override
  String get forgotRememberPassword => 'ኮዱን አስታወሱ? ';
  @override
  String get forgotPhoneComingSoon => 'ስልክ ቁጥር ዳግም ማስጀመሪያ — በቅርብ ይመጣል';
  @override
  String get forgotTabPhone => 'ስልክ';

  // ── Reset password ────────────────────────────────────────────────────────
  @override
  String get resetTitle => 'አዲስ የይለፍ ቃል';
  @override
  String get resetSubtitle => 'የሚያስታውሱት ጠንካራ የይለፍ ቃል ለመምረጥ ይሞክሩ።';
  @override
  String get resetTokenLabel => 'ከኢሜልዎ የተቀበሉት ኮድ';
  @override
  String get resetNewPasswordLabel => 'አዲስ የይለፍ ቃል';
  @override
  String get resetConfirmLabel => 'የይለፍ ቃል ያረጋግጡ';
  @override
  String get resetRequirementsTitle => 'የይለፍ ቃል መስፈርቶች';
  @override
  String get resetReqLength => 'ቢያንስ 8 ቁምፊዎች';
  @override
  String get resetReqUpper => 'አንድ ትልቅ ፊደል (A–Z)';
  @override
  String get resetReqNumber => 'አንድ ቁጥር (0–9)';
  @override
  String get resetReqSpecial => 'አንድ ልዩ ምልክት (!@#\$)';
  @override
  String get resetSaveButton => 'አስቀምጥ እና ግባ';
  @override
  String get resetSuccessMessage => 'የይለፍ ቃልዎ ተቀይሯል። እባክዎ ይግቡ።';

  // ── Profile screen ────────────────────────────────────────────────────────
  @override
  String get profileTitle => 'ፕሮፋይል';
  @override
  String get profileSignedOut => 'አልገቡም';
  @override
  String get profileMemberBadge => 'አባል';
  @override
  String get profileLogout => 'ውጣ';
  @override
  String get profileDeleteAccount => 'መለያ ሰርዝ';
  @override
  String get profileEditButton => 'ፕሮፋይል አስተካክል';
  @override
  String get profileAchievements => 'ስኬቶች';
  @override
  String get profileStatStreak => 'የቀን ስኬቶች';
  @override
  String get profileStatBookmarks => 'ምልክት';
  @override
  String get profileStatPlan => 'ዕቅድ';
  @override
  String get profileDeleteTitle => 'መለያ ይሰረዝ?';
  @override
  String get profileDeleteMessage => 'ሁሉም ዳታ ይጠፋል። ይህ ድርጊት ሊመለስ አይችልም።';
  @override
  String get profileDeleteCancel => 'ይቅር';
  @override
  String get profileDeleteConfirm => 'ሰርዝ';
  @override
  String get achievementFirstDayTitle => 'መጀመሪያ ቀን';
  @override
  String get achievementFirstDaySub => 'First Day';
  @override
  String get achievement7DayTitle => '፯ ቀን ሰንሰለት';
  @override
  String get achievement7DaySub => '7-Day Streak';
  @override
  String get achievementPsalmTitle => 'የምዝሙሩ';
  @override
  String get achievementPsalmSub => 'Psalm Reader';

  // ── Profile editing ───────────────────────────────────────────────────────
  @override
  String get profileFirstName => 'ስም';
  @override
  String get profileLastName => 'ያባት ስም';
  @override
  String get profileSaveChanges => 'ለውጦች አስቀምጥ';
  @override
  String get profileSaved => 'ፕሮፋይሉ ተዘምኗል';
  @override
  String get profileSectionInfo => 'የመለያ መረጃ';
  @override
  String get profileSectionSecurity => 'ደህንነት';
  @override
  String get profileSectionPreferences => 'ምርጫዎች';
  @override
  String get profileChangePhoto => 'ፎቶ ቀይር';
  @override
  String get profileGoogleNote => 'Google አካውንት ነዎት — ኢሜይሉ ሊቀየር አይችልም';
  @override
  String get profileChangePassword => 'ይለፍ ቃሉን ቀይር';
  @override
  String get profileCurrentPassword => 'አሁን ያለ ይለፍ ቃሉ';
  @override
  String get profileNewPassword => 'አዲስ ይለፍ ቃሉ';
  @override
  String get profileConfirmNewPassword => 'ይለፍ ቃሉን ያረጋግጡ';
  @override
  String get profileUpdatePassword => 'ይለፍ ቃሉን ዘምን';
  @override
  String get profilePasswordChanged => 'ይለፍ ቃሉ ተቀይሯል';
  @override
  String get profilePasswordMismatch => 'ይለፍ ቃሎቹ አይዛመዱም';
  @override
  String get profileUpdateFailed => 'ማዘምን አልተሳካም። እንደገና ይሞክሩ።';

  // ── Verse card sheet ──────────────────────────────────────────────────────
  @override
  String get cardSheetTitle => 'ቅጥ እና አካፍል';
  @override
  String get cardTabBackground => 'ዳራ';
  @override
  String get cardTabText => 'ጽሑፍ';
  @override
  String get cardTabReference => 'ምንጭ';
  @override
  String get cardTabRatio => 'መጠን';
  @override
  String get cardShare => 'አጋራ';
  @override
  String get cardSaveToGallery => 'አስቀምጥ';
  @override
  String get cardSaved => 'ወደ ጋለሪ ተቀምጧል';
  @override
  String get cardSaveFailed => 'ማስቀመጥ አልተሳካም';
  @override
  String get cardBgColours => 'ቀለማት';
  @override
  String get cardBgGradients => 'ቅብ';
  @override
  String get cardBgGallery => 'ጋለሪ';
  @override
  String get cardBgFrame => 'ክፈፍ';
  @override
  String get cardFontLabel => 'ፊደል';
  @override
  String get cardSizeLabel => 'መጠን';
  @override
  String get cardColorLight => 'ብርሃን';
  @override
  String get cardColorDark => 'ጨለማ';
  @override
  String get cardRefGeez => 'ግዕዝ';
  @override
  String get cardRefArabic => '123';
  @override
  String get cardRefAmharic => 'አማርኛ';
  @override
  String get cardRefEnglish => 'English';
  @override
  String get cardRefShow => 'ምንጩን አሳይ';
  @override
  String get cardRefNumeralStyle => 'የቁጥር ዘይቤ';
  @override
  String get cardRefNumeralHint => 'የቁጥር ስርዓት ይምረጡ';
  @override
  String get cardRefBookLang => 'የመጽሐፍ ስም ቋንቋ';
  @override
  String get cardRefBookLangHint => 'የምንጭ መጽሐፍ ማሳያ ቋንቋ';
  @override
  String get cardTextColour => 'ቀለም';
  @override
  String get cardTextAlignment => 'አሰላለፍ';
  @override
  String get cardRatioSquare => 'ካሬ';
  @override
  String get cardRatioPortrait => 'ቁመት';
  @override
  String get cardRatioStory => 'ስቶሪ';
  @override
  String get cardFrameNone => 'ያለ ፍሬም';
  @override
  String get cardFrameSimple => 'ቀላል';
  @override
  String get cardFrameOrnate => 'ያጌጠ';
  @override
  String get cardFrameManuscript => 'ብራና';
  @override
  String get cardImagePickFailed => 'ምስል መምረጥ አልተቻለም';
  @override
  String get cardShareAsText => 'እንደ ጽሑፍ አጋራ';

  // ── Notifications ─────────────────────────────────────────────────────────
  @override
  String get notificationPermissionDenied => 'ማሳወቂያዎችን ለመላክ ፈቃድ አልተሰጠም';
  @override
  String dailyVerseSet(String time) => 'የዕለቱ ጥቅስ ማሳወቂያ በ $time ተዘጋጅቷል';
  @override
  String get dailyVerseOff => 'የዕለቱ ጥቅስ ማሳወቂያ ጠፍቷል';
  @override
  String dailyVerseUpdated(String time) => 'የዕለቱ ጥቅስ ማሳወቂያ ወደ $time ተቀይሯል';
  @override
  String get readingReminderOff => 'የንባብ ሰዓት ማሳወቂያ ጠፍቷል';
  @override
  String readingReminderSet(String time) => 'የንባብ ሰዓት ማሳወቂያ በ $time ተዘጋጅቷል';
  @override
  String readingReminderUpdated(String time) => 'የንባብ ሰዓት ማሳወቂያ ወደ $time ተቀይሯል';

  // ── Onboarding ────────────────────────────────────────────────────────────
  @override
  String get onboardingSkip => 'እለፍ';
  @override
  String get onboardingNext => 'ቀጣይ';
  @override
  String get onboardingDone => 'ጀምር';

  @override
  String get onboardingWelcomeTitle => 'መጽሐፍ ቅዱስ';
  @override
  String get onboardingWelcomeCanonNote =>
      'የ ፹፩ (81) መጻሕፍት የኢትዮጵያ ኦርቶዶክስ ተዋሕዶ ቤተ ክርስቲያን የቅዱሳት መጻሕፍት ስብስብ።';

  @override
  String get onboardingPrefsTitle => 'የንባብ ምርጫዎች';
  @override
  String get onboardingPrefsSubtitle =>
      'የፊደል መጠንን፣ ቋንቋን እና የቁጥር ስርዓትን እንደ ፍላጎትዎ ያስተካክሉ።';
  @override
  String get onboardingPreviewVerseText =>
      'በመጀመሪያ ቃል ነበረ፥ ቃልም በእግዚአብሔር ዘንድ ነበረ፥ ቃልም እግዚአብሔር ነበረ። (ዮሐንስ ፩:፩)';

  @override
  String get onboardingActionsTitle => 'የጥቅስ ተግባራት';
  @override
  String get onboardingActionsSubtitle =>
      'ጥቅሶችን ይምረጡ፤ ያጉሉ፣ ማስታወሻ ይጻፉ፣ ይቅዱ ወይም ያጋሩ።';

  @override
  String get onboardingSignInTitle => 'መለያ ያስገቡ (በምርጫ)';
  @override
  String get onboardingSignInSubtitle =>
      'መለያ በመክፈት ማስታወሻዎችዎን እና ስብስቦችዎን በደመና ላይ ያስቀምጡ። ያለ መለያም ሙሉ የመጽሐፍ ቅዱስ ንባብ እና አገልግሎቶች ከመስመር ውጭ (Offline) ይሰራሉ።';
  @override
  String get onboardingSignInBtn => 'ይግቡ';
  @override
  String get onboardingNotNowBtn => 'አሁን አይደለም';

  @override
  String get meShowIntroduction => 'መግቢያውን አሳይ';

  @override
  String get readerVerseActionHint =>
      'ጥቅስ ላይ በመጫን ማጉላት፣ ማስታወሻ መጻፍ ወይም ማጋራት ይችላሉ';
  @override
  String get editionsTitle => 'የመጽሐፍ ቅዱስ ዕትሞች';
  @override
  String get editionsSubtitle => 'ዕትም ይምረጡ ወይም አዲስ ያውርዱ';
  @override
  String get editionsInstalled => 'በመሣሪያዎ ላይ';
  @override
  String get editionsAvailable => 'ሊወርዱ የሚችሉ';
  @override
  String get editionDownload => 'አውርድ';
  @override
  String get editionUpdate => 'አዘምን';
  @override
  String get editionRemove => 'አስወግድ';
  @override
  String get editionUse => 'ተጠቀም';
  @override
  String get editionActive => 'በሥራ ላይ';
  @override
  String get editionBuiltIn => 'ከመተግበሪያው ጋር የመጣ';
  @override
  String get editionDownloading => 'በማውረድ ላይ…';
  @override
  String get editionRemoveTitle => 'ዕትሙ ይወገድ?';
  @override
  String editionRemoveBody(String title) =>
      '$title ከመሣሪያዎ ይወገዳል። ማስታወሻዎችዎና ምልክቶችዎ አይጠፉም፤ ዕትሙን ዳግም ማውረድ ይችላሉ።';
  @override
  String get editionRemoveConfirm => 'አስወግድ';
  @override
  String get editionCancel => 'ተወው';
  @override
  String editionUpdated(String title) => '$title ተዘምኗል';
  @override
  String editionUpToDate(String title) => '$title ወቅታዊ ነው';
  @override
  String editionPublishedBy(String publisher) => 'በ$publisher የታተመ';
  @override
  String get editionPublicDomain => 'የሕዝብ ንብረት';
  @override
  String get editionSwitchTitle => 'ዕትም ይምረጡ';
  @override
  String get editionSwitchSubtitle => 'የሚያነቡትን ጽሑፍ ይቀይሩ';
  @override
  String get editionManage => 'ዕትሞችን አስተዳድር';
  @override
  String editionMoreAvailable(int count) => '$count ተጨማሪ ሊወርዱ ይችላሉ';
  @override
  String editionSwitched(String title) => 'አሁን $title እያነበቡ ነው';
  @override
  String editionBookMissing(String title) => 'ይህ መጽሐፍ በ$title ውስጥ የለም';
  @override
  String get editionUpdateAvailable => 'ማዘመኛ አለ';
  @override
  String get editionsFilterAll => 'ሁሉም';
  @override
  String get editionsNoneForFilter => 'በዚህ ቋንቋ ዕትም የለም';
  @override
  String get editionsCheckUpdates => 'ዝማኔ ፈትሽ';
  @override
  String get editionsActiveLabel => 'አሁን በንባብ ላይ';
  @override
  String editionsOnDeviceCount(int installed, int total) =>
      'ከ$total ውስጥ $installed በመሣሪያዎ ላይ';
  @override
  String editionMetaBooks(String count) => '$count መጻሕፍት';
  @override
  String editionMetaChapters(String count) => '$count ምዕራፎች';
  @override
  String editionMetaVerses(String count) => '$count ጥቅሶች';
  @override
  String get onboardingSampleVerseNumber => '፩';

  @override
  String get onboardingSampleVerseText =>
      'በመጀመሪያ ቃል ነበረ፥ ቃልም በእግዚአብሔር ዘንድ ነበረ፥ ቃልም እግዚአብሔር ነበረ።';

  // ── Audio reading ──────────────────────────────────────────────────────────
  @override
  String get voiceSettingsTitle => 'የንባብ ድምፅ';
  @override
  String get voiceSectionKey => 'የአዲስ AI ቁልፍ';
  @override
  String get voiceSectionVoices => 'ድምፅ ይምረጡ';
  @override
  String get voiceKeyIntro =>
      'ድምፅ ንባብ የሚሠራው በአዲስ AI ነው። የራስዎን ቁልፍ ከአዲስ AI አግኝተው እዚህ ያስገቡ።';
  @override
  String get voiceKeyGetOne => 'ቁልፍ ያግኙ';
  @override
  String get voiceKeyLinkCopied => 'አገናኙ ተቀድቷል';
  @override
  String get voiceKeyFieldHint => 'ቁልፍዎን እዚህ ይለጥፉ';
  @override
  String get voiceKeySave => 'አስቀምጥ';
  @override
  String get voiceKeySaved => 'ቁልፍዎ ተቀምጧል';
  @override
  String get voiceKeyChange => 'ቁልፍ ቀይር';
  @override
  String get voiceKeyRemove => 'ቁልፍ አስወግድ';
  @override
  String get voiceKeyRemoved => 'ቁልፉ ተወግዷል';
  @override
  String get voiceKeyRejected => 'ቁልፉ ተቀባይነት አላገኘም። እባክዎ ያረጋግጡ።';
  @override
  String get voiceKeyRequired => 'ድምፅ ለመስማት መጀመሪያ ቁልፍዎን ያስገቡ።';
  @override
  String get voiceLoadFailed => 'የድምፅ ዝርዝሩን መጫን አልተቻለም።';
  @override
  String get voiceListEmpty => 'ለዚህ ቋንቋ ድምፅ አልተገኘም።';
  @override
  String get voiceRetry => 'እንደገና ሞክር';
  @override
  String get voicePreview => 'ስማ';
  @override
  String get voiceSelectedBadge => 'ተመርጧል';
  @override
  String get voiceDefaultBadge => 'ነባር';
  @override
  String get voiceGenderMale => 'ወንድ';
  @override
  String get voiceGenderFemale => 'ሴት';
  @override
  String voiceSelectedToast(String name) => '$name ተመርጧል';

  // ── Parallel reading ──────────────────────────────────────────────────────
  @override
  String get parallelSectionTitle => 'ጎን ለጎን ንባብ';
  @override
  String get parallelSectionSubtitle => 'ሁለት ትርጉሞችን በአንድ ገጽ ያንብቡ';
  @override
  String get parallelShowAlongside => 'ጎን ለጎን አሳይ';
  @override
  String get parallelSettingLabel => 'ጎን ለጎን ትርጉም';
  @override
  String get parallelOff => 'ጠፍቷል';
  @override
  String parallelEnabled(String title) => '$title ጎን ለጎን እየታየ ነው';
  @override
  String get parallelDisabled => 'ጎን ለጎን ንባብ ጠፍቷል';
  @override
  String parallelBookMissing(String title) => 'ይህ መጽሐፍ በ$title ትርጉም የለም';

  // ── Backup & Restore ──────────────────────────────────────────────────────
  @override
  String get sectionBackup => 'መጠባበቂያ (Backup)';
  @override
  String get backupExportJson => 'መጠባበቂያ ፋይል አውጣ (JSON)';
  @override
  String get backupExportJsonHint => 'የJSON ባክአፕ ፋይል ያዘጋጃል';
  @override
  String get backupExportMarkdown => 'በMarkdown ፋይል አውጣ';
  @override
  String get backupExportMarkdownHint => 'ለቀላል ንባብ የሚሆን ፋይል (ሊመለስ የማይችል)';
  @override
  String get backupImport => 'መጠባበቂያ ፋይል መልስ (Import)';
  @override
  String get backupImportHint => 'ማስታወሻዎችን ከJSON ፋይል ይመልሳል';
  @override
  String get backupMarkdownDisclaimer => 'ይህ ፋይል ለንባብ ብቻ የተዘጋጀ ነው (መመለስ አይቻልም)';
  @override
  String get backupMarkdownBody =>
      'ዕልባቶችዎ፣ ምልክቶችዎ እና ማስታወሻዎችዎ ለማንበብ፣ ለማተም ወይም ለማስቀመጥ በሚመች ሰነድ ሆነው ይጻፋሉ።';
  @override
  String get backupConfirmExport => 'አውጣ';
  @override
  String get backupConflictSkip => 'ነባሩን አስቀር';
  @override
  String get backupConflictMerge => 'ቀላቅል';
  @override
  String get backupConflictReplace => 'ተካ';
  @override
  String get backupConflictTitle => 'የግጭት መፍቻ መመሪያ';
  @override
  String get backupCancel => 'ተወው';
  @override
  String get backupConfirmImport => 'አስገባ';
  @override
  String backupPreviewText(int b, int h, int n, int existing) =>
      '$b ዕልባቶች፣ $h ምልክቶች፣ $n ማስታወሻዎች — $existing አስቀድመው አሉ';
  @override
  String get backupImportSuccess => 'መጠባበቂያው በተሳካ ሁኔታ ተመልሷል';
  @override
  String get backupImportFailed => 'ማስገባት አልተሳካም — ፋይሉ ተበላሽቶ ሊሆን ይችላል';
  @override
  String get backupExportSuccess => 'መጠባበቂያው በተሳካ ሁኔታ ወጥቷል';
  @override
  String get backupNoFilePicked => 'ምንም መጠባበቂያ ፋይል አልተመረጠም';

  // ── Local Web Reader ──────────────────────────────────────────────────────
  @override
  String get sectionDevice => 'መሣሪያ';
  @override
  String get webReaderTitle => 'የአካባቢ ድር አንባቢ';
  @override
  String get webReaderHint => 'በኮምፒውተርህ ላይ አንብብ';
  @override
  String get webReaderStart => 'አስጀምር';
  @override
  String get webReaderStop => 'አቁም';
  @override
  String get webReaderStarting => 'በመጀመር ላይ…';
  @override
  String get webReaderRunningHint => 'በዚሁ WiFi ላይ ካለ አሳሽ ይህን አድራሻ ክፈት';
  @override
  String get webReaderBackgroundHint =>
      'መተግበሪያውን ብትዘጋም ማገልገሉን ይቀጥላል። ከማሳወቂያው ላይ ማቆም ትችላለህ።';
  @override
  String get webReaderCopy => 'ቅዳ';
  @override
  String get webReaderCopied => 'አድራሻው ተቀድቷል';
  @override
  String get webReaderScanHint => 'ለማጉላት ንካ';
  @override
  String get webReaderQrTitle => 'በካሜራ አንብብ';
  @override
  String get webReaderClose => 'ዝጋ';
  @override
  String get webReaderNoNetwork =>
      'ከWiFi ጋር አልተገናኘም። መጀመሪያ ከአውታረ መረብ ጋር ተገናኝ።';
  @override
  String get webReaderNoPort => 'ወደቡ በሌላ መተግበሪያ ተይዟል።';
}
