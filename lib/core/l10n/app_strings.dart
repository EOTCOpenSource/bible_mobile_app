/// Abstract contract for all user-facing strings.
/// Add a new getter/method here, then implement it in
/// [AmStrings] and [EnStrings].
abstract class AppStrings {
  const AppStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navHome;
  String get navBooks;
  String get navSearch;
  String get navSaved;
  String get navMe;

  // ── Home header ───────────────────────────────────────────────────────────
  String get welcomeGreeting;

  // ── Reading streak ────────────────────────────────────────────────────────
  String get streakConsecutiveLabel;
  String get streakDaysSuffix;
  String get streakReadTodayHint;
  String get streakReadTodayBtn;

  // ── Daily verse ───────────────────────────────────────────────────────────
  String get dailyVerseTag;

  // ── Continue reading ──────────────────────────────────────────────────────
  String get continueReadingTitle;
  String completedPercent(int pct);

  // ── Reading plans ─────────────────────────────────────────────────────────
  String get readingPlansTitle;
  String get viewAll;
  String daysCount(int n);

  // ── Me / Settings screen ──────────────────────────────────────────────────
  String get meTitle;
  String get meProfileEditBadge;

  // Section headers (Amharic half — English half is always uppercase ASCII)
  String get sectionReading;
  String get sectionLanguage;
  String get sectionNumbers;
  String get sectionReminders;

  // Reading group
  String get settingTranslation;
  String get settingTranslationValue;
  String get settingReadingPrefs;
  String get settingReadingPrefsHint;
  String get settingNightMode;
  String get settingNightModeHint;
  String get settingAudio;
  String get settingAudioAction;

  // Language group
  String get settingLanguage;
  String get langAmharic;
  String get langEnglish;

  // Numbers group
  String get settingGeezNums;
  String get settingGeezNumsHint;

  // Reminders group
  String get settingDailyVerse;
  String get settingDailyVerseHint;
  String get settingReadingTime;
  String get settingReadingTimeHint;

  // ── Books tab ─────────────────────────────────────────────────────────────
  String get booksTitle;
  String get booksOldTestament;
  String get booksNewTestament;
  String booksSubtitle(String countStr);
  String get booksFilterAll;
  String get booksFilterLaw;       // Pentateuch — books 1–5
  String get booksFilterHistory;   // Historical — books 6–17
  String get booksFilterWisdom;    // Poetry & Wisdom — books 18–22
  String get booksFilterProphets;  // Prophetic — books 23–39
  String get booksFilterOther;     // EOTC-specific OT — books 40+
  String get booksFilterGospels;
  String get booksFilterActs;
  String get booksFilterPauline;    // Pauline Epistles — books 52–65
  String get booksFilterGeneral;    // General Epistles — books 66–72
  String get booksFilterRevelation; // Revelation & Apocalyptic — books 73+
  String get booksChapterSuffix;  // e.g. "ምዕ." / "chs."

  // ── Chapter selector ──────────────────────────────────────────────────────
  String get chapSelectorLastRead;       // "የቀደሙቦ ቦታ" / "Where you left off"
  String get chapSelectorContinueBtn;    // "ቀጣ" / "Continue"
  String get chapSelectorVerseLabel;     // "ቁጥ" / "Vs"
  String get chapSelectorProgressSuffix; // "ተነቧል" / "read"
  String get chapSelectorChapNosLabel;   // "ምዕራፍ ቁጥሮች" / "Chapter Nos."
  String get legendCurrent;              // "አሁን" / "Now"
  /// Highlight for the next chapter to read (first unread in order).
  String get legendNextChapter;
  String get legendUnread;               // "ያልተነበበ" / "Unread"
  String get legendBookmark;             // "የተመዘገበ" / "Bookmarked"

  // ── Reading Settings ──────────────────────────────────────────────────────
  String get readingSettingsTitle;
  String get readingSettingsBodyFont;
  String get readingSettingsTitleFont;
  String get readingSettingsFontSize;
  String get readingSettingsNightMode;
  String get readingSettingsPreview;
  String get readingSettingsReset;
  String get readingSettingsContinuous;

  // ── Search ───────────────────────────────────────────────────────────────
  String get searchHint;
  String get searchPrompt;
  String get searchNoResults;
  String searchResultCount(int n);
  String get searchRunBtn;
  String get searchSmartMode;
  String get searchAllWords;
  String get searchInAll;
String get searchScopeTitle;
  String get searchPickBook;
  String get searchOrPickBook;

  // ── Reader ────────────────────────────────────────────────────────────────
  String get chapterAbbr;       // short label for chapter, e.g. "ምዕ" / "Ch"
  String get verseBookmark;
  String get verseHighlight;
  String get verseNote;
  String get verseCopy;
  String get verseShare;
  String get comingSoon;

  // ── Auth — shared ─────────────────────────────────────────────────────────
  String get authEmail;
  String get authEmailRequired;
  String get authEmailInvalid;
  String get authPassword;
  String get authPasswordRequired;
  String get authConnectionError;

  // ── Auth — login ──────────────────────────────────────────────────────────
  String get loginTitle;
  String get loginSubtitle;
  String get loginRememberMe;
  String get loginForgotPassword;
  String get loginButton;
  String get loginOrDivider;
  String get loginNoAccount;
  String get loginRegisterLink;
  String get loginVerseQuote;
  String get loginAccountLocked;
  String get loginGoogleFailed;
  String get loginFacebookComingSoon;

  // ── Auth — register ───────────────────────────────────────────────────────
  String get registerTitle;
  String get registerSubtitle;
  String get registerFullName;
  String get registerFullNameRequired;
  String get registerFullNameTooShort;
  String get registerPasswordTooShort;
  String get registerAcceptTerms;
  String get registerButton;
  String get registerHaveAccount;
  String get registerLoginLink;
  String get registerTermsText;
  String get passwordWeak;
  String get passwordFair;
  String get passwordGood;
  String get passwordStrong;

  // ── Auth — OTP ────────────────────────────────────────────────────────────
  String get otpTitle;
  String get otpSentPrefix;
  String get otpSentSuffix;
  String otpDigitsRequired(int n);
  String get otpNotReceived;
  String otpResendIn(String t);
  String get otpResend;
  String get otpVerifyButton;
  String get otpChangePhone;
  String get otpChangeEmail;
  String get otpResendFailed;
}
