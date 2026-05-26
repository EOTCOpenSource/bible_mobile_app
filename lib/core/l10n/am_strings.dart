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
  @override
  String get readingPlansSyncPrompt =>
      'የንባብ ዕቅዶዎን በሁሉም መሣሪያዎች ለማስተባበር ይግቡ';
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

  // ── Auth — shared ─────────────────────────────────────────────────────────
  @override String get authEmail             => 'ኢሜል';
  @override String get authEmailRequired     => 'ኢሜል ያስፈልጋል';
  @override String get authEmailInvalid      => 'ትክክለኛ ኢሜል ያስገቡ';
  @override String get authPassword          => 'የይለፍ ቃል';
  @override String get authPasswordRequired  => 'የይለፍ ቃል ያስፈልጋል';
  @override String get authConnectionError   => 'ግንኙነት አልተሳካም። ድጋሚ ይሞክሩ።';

  // ── Auth — login ──────────────────────────────────────────────────────────
  @override String get loginTitle            => 'እንኳን ደህና መጡ';
  @override String get loginSubtitle         => 'መጽሐፍ ቅዱስ ማንበብ ለመቀጠል ይግቡ።';
  @override String get loginRememberMe       => 'አስታወስኝ';
  @override String get loginForgotPassword   => 'የይለፍ ቃል ረሳህ?';
  @override String get loginButton           => 'ግባ';
  @override String get loginOrDivider        => 'ወይም በነዚህ ይግቡ';
  @override String get loginNoAccount        => 'አካውንት የለዎትም? ';
  @override String get loginRegisterLink     => 'ይ​መዝ​ገቡ';
  @override String get loginVerseQuote       => 'ቃልህ ለመንገዴ ብርሃን ነው';
  @override String get loginAccountLocked    => 'መለያዎ ተቆልፏል። ከ2 ሰዓት በኋላ ይሞክሩ።';
  @override String get loginGoogleFailed     => 'Google ግባ አልተሳካም። ድጋሚ ይሞክሩ።';
  @override String get loginFacebookComingSoon => 'Facebook Sign In — በቅርብ ይመጣል';

  // ── Auth — register ───────────────────────────────────────────────────────
  @override String get registerTitle             => 'አካውንት ይፍጠሩ';
  @override String get registerSubtitle          => 'የ ንባብ ሂደቶን፣ ኖቶቹን፣ እና ቀለሞችን ';
  @override String get registerFullName          => 'ሙሉ ስም';
  @override String get registerFullNameRequired  => 'ሙሉ ስም ያስፈልጋል';
  @override String get registerFullNameTooShort  => 'ስም ቢያንስ 2 ፊደላት ያስፈልጋሉ';
  @override String get registerPasswordTooShort  => 'ቢያንስ 8 ቁምፊዎች ያስፈልጋሉ';
  @override String get registerAcceptTerms       => 'ውሎቹን እና ሁኔታዎቹን ይቀበሉ';
  @override String get registerButton            => 'ይ​መዝ​ጋቡ';
  @override String get registerHaveAccount       => 'መለያ አለዎት? ';
  @override String get registerLoginLink         => 'ይ​ግቡ';
  @override String get registerTermsText         => 'I accept the Community Terms and Privacy Policy.';
  @override String get passwordWeak              => 'ደካማ';
  @override String get passwordFair              => 'መካከለኛ';
  @override String get passwordGood              => 'ጥሩ';
  @override String get passwordStrong            => 'ጠንካራ';

  // ── Auth — OTP ────────────────────────────────────────────────────────────
  @override String get otpTitle          => 'ኮድዎን ያረጋግጡ';
  @override String get otpSentPrefix     => 'ወደ ';
  @override String get otpSentSuffix     => ' 6 አሃዝ ኮድ ልከናል። አባክዎ ከታች ያስገቡ።';
  @override String otpDigitsRequired(int n) => 'የ$n ቁጥር ኮድ ያስፈልጋል';
  @override String get otpNotReceived    => 'ኮድ አልደረሰዎትም? ';
  @override String otpResendIn(String t) => 'ድጋሚ ላክ $t';
  @override String get otpResend         => 'ድጋሚ ላክ';
  @override String get otpVerifyButton   => 'አረጋጥ';
  @override String get otpChangePhone    => 'ስልክ ቁጥር ለውጥ';
  @override String get otpChangeEmail    => 'ኢሜል ለውጥ';
  @override String get otpResendFailed   => 'ኮድ መላክ አልተሳካም። ድጋሚ ይሞክሩ።';

  // ── Forgot password ───────────────────────────────────────────────────────
  @override String get forgotTitle            => 'የይለፍ ቃል ረሱ?';
  @override String get forgotSubtitle         => 'ምንም አያስቡ። የተመዘገቡበትን ኢሜልዎን ያስገቡ፤ የዳግም ማስጀመሪያ ኮድ እንልካለን።';
  @override String get forgotEmailLabel       => 'የተመዘገቡበት ኢሜል';
  @override String get forgotEmailHelper      => 'የዳግም ማስጀመሪያ ኮዱ ወደዚህ ኢሜል ይላካል።';
  @override String get forgotPhoneLabel       => 'የተመዘገቡ ስልክ ቁጥር';
  @override String get forgotPhoneHelper      => 'የዳግም ማስጀመሪያ ኮዱ ወደዚህ ስልክ ቁጥር ይላካል።';
  @override String get forgotSendButton       => 'ኮድ ላክ';
  @override String get forgotRememberPassword => 'ኮዱን አስታወሱ? ';
  @override String get forgotPhoneComingSoon  => 'ስልክ ቁጥር ዳግም ማስጀመሪያ — በቅርብ ይመጣል';
  @override String get forgotTabPhone         => 'ስልክ';

  // ── Reset password ────────────────────────────────────────────────────────
  @override String get resetTitle             => 'አዲስ የይለፍ ቃል';
  @override String get resetSubtitle          => 'የሚያስታውሱት ጠንካራ የይለፍ ቃል ለመምረጥ ይሞክሩ።';
  @override String get resetTokenLabel        => 'ከኢሜልዎ የተቀበሉት ኮድ';
  @override String get resetNewPasswordLabel  => 'አዲስ የይለፍ ቃል';
  @override String get resetConfirmLabel      => 'የይለፍ ቃል ያረጋግጡ';
  @override String get resetRequirementsTitle => 'የይለፍ ቃል መስፈርቶች';
  @override String get resetReqLength         => 'ቢያንስ 8 ቁምፊዎች';
  @override String get resetReqUpper          => 'አንድ ትልቅ ፊደል (A–Z)';
  @override String get resetReqNumber         => 'አንድ ቁጥር (0–9)';
  @override String get resetReqSpecial        => 'አንድ ልዩ ምልክት (!@#\$)';
  @override String get resetSaveButton        => 'አስቀምጥ እና ግባ';
  @override String get resetSuccessMessage    => 'የይለፍ ቃልዎ ተቀይሯል። እባክዎ ይግቡ።';

  // ── Profile screen ────────────────────────────────────────────────────────
  @override String get profileTitle            => 'ፕሮፋይል';
  @override String get profileMemberBadge      => 'አባል';
  @override String get profileLogout           => 'ውጣ';
  @override String get profileDeleteAccount    => 'መለያ ሰርዝ';
  @override String get profileEditButton       => 'ፕሮፋይል አስተካክል';
  @override String get profileAchievements     => 'ስኬቶች';
  @override String get profileStatStreak       => 'የቀን ስኬቶች';
  @override String get profileStatBookmarks    => 'ምልክት';
  @override String get profileStatPlan         => 'ዕቅድ';
  @override String get profileDeleteTitle      => 'መለያ ይሰረዝ?';
  @override String get profileDeleteMessage    => 'ሁሉም ዳታ ይጠፋል። ይህ ድርጊት ሊመለስ አይችልም።';
  @override String get profileDeleteCancel     => 'ይቅር';
  @override String get profileDeleteConfirm    => 'ሰርዝ';
  @override String get achievementFirstDayTitle => 'መጀመሪያ ቀን';
  @override String get achievementFirstDaySub   => 'First Day';
  @override String get achievement7DayTitle     => '፯ ቀን ሰንሰለት';
  @override String get achievement7DaySub       => '7-Day Streak';
  @override String get achievementPsalmTitle    => 'የምዝሙሩ';
  @override String get achievementPsalmSub      => 'Psalm Reader';

  // ── Profile editing ───────────────────────────────────────────────────────
  @override String get profileFirstName          => 'ስም';
  @override String get profileLastName           => 'ያባት ስም';
  @override String get profileSaveChanges        => 'ለውጦች አስቀምጥ';
  @override String get profileSaved              => 'ፕሮፋይሉ ተዘምኗል';
  @override String get profileSectionInfo        => 'የመለያ መረጃ';
  @override String get profileSectionSecurity    => 'ደህንነት';
  @override String get profileSectionPreferences => 'ምርጫዎች';
  @override String get profileChangePhoto        => 'ፎቶ ቀይር';
  @override String get profileGoogleNote         => 'Google አካውንት ነዎት — ኢሜይሉ ሊቀየር አይችልም';
  @override String get profileChangePassword     => 'ይለፍ ቃሉን ቀይር';
  @override String get profileCurrentPassword    => 'አሁን ያለ ይለፍ ቃሉ';
  @override String get profileNewPassword        => 'አዲስ ይለፍ ቃሉ';
  @override String get profileConfirmNewPassword => 'ይለፍ ቃሉን ያረጋግጡ';
  @override String get profileUpdatePassword     => 'ይለፍ ቃሉን ዘምን';
  @override String get profilePasswordChanged    => 'ይለፍ ቃሉ ተቀይሯል';
  @override String get profilePasswordMismatch   => 'ይለፍ ቃሎቹ አይዛመዱም';
  @override String get profileUpdateFailed       => 'ማዘምን አልተሳካም። እንደገና ይሞክሩ።';

}
