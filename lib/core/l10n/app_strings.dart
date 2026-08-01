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
  String get dailyVerseUnavailable;

  // ── Continue reading ──────────────────────────────────────────────────────
  String get continueReadingTitle;
  String completedPercent(int pct);

  // ── Reading plans ─────────────────────────────────────────────────────────
  String get readingPlansTitle;
  String get viewAll;
  String daysCount(int n);
  String get readingPlansSyncPrompt;
  String get continueWithoutAccount;

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

  /// The deuterocanon — the books the 81-book EOTC canon has and the
  /// protestant 66 does not.
  String get booksDeuterocanonical;
  String booksSubtitle(String countStr);
  String get booksFilterAll;
  String get booksFilterLaw; // Pentateuch — books 1–5
  String get booksFilterHistory; // Historical — books 6–17
  String get booksFilterWisdom; // Poetry & Wisdom — books 18–22
  String get booksFilterProphets; // Prophetic — books 23–39
  String get booksFilterOther; // EOTC-specific OT — books 40+
  String get booksFilterGospels;
  String get booksFilterActs;
  String get booksFilterPauline; // Pauline Epistles — books 52–65
  String get booksFilterGeneral; // General Epistles — books 66–72
  String get booksFilterRevelation; // Revelation & Apocalyptic — books 73+
  String get booksChapterSuffix; // e.g. "ምዕ." / "chs."

  // ── Chapter selector ──────────────────────────────────────────────────────
  String get chapSelectorLastRead; // "የቀደሙቦ ቦታ" / "Where you left off"
  String get chapSelectorContinueBtn; // "ቀጣ" / "Continue"
  String get chapSelectorVerseLabel; // "ቁጥ" / "Vs"
  String get chapSelectorProgressSuffix; // "ተነቧል" / "read"
  String get chapSelectorChapNosLabel; // "ምዕራፍ ቁጥሮች" / "Chapter Nos."
  String get legendCurrent; // "አሁን" / "Now"
  /// Highlight for the next chapter to read (first unread in order).
  String get legendNextChapter;
  String get legendUnread; // "ያልተነበበ" / "Unread"
  String get legendBookmark; // "የተመዘገበ" / "Bookmarked"

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

  // ── Saved / Collection ───────────────────────────────────────────────────
  String get savedEyebrow;
  String get savedTitle;
  String get savedHighlights;
  String get savedBookmarks;
  String get savedNotes;
  String get savedFilterAll;
  String get savedFilterOld;
  String get savedFilterNew;
  String get savedPickBook;
  String get savedAllBooks;
  String get savedPickChapter;
  String get savedAllChapters;
  String get savedAllChaptersShort;
  String savedChapterLabel(int chapter);
  String get savedToday;
  String get savedYesterday;
  String savedDaysAgo(int days);
  String get savedEmptyHighlightsTitle;
  String get savedEmptyHighlightsHint;
  String get savedEmptyBookmarksTitle;
  String get savedEmptyBookmarksHint;
  String get savedEmptyNotesTitle;
  String get savedEmptyNotesHint;
  String get savedEdit;
  String get savedDelete;
  String get savedDeleteNoteTitle;
  String savedDeleteNoteMessage(String reference);
  String get savedDeleteBookmarkTitle;
  String savedDeleteBookmarkMessage(String reference);
  String get savedDeleteHighlightTitle;
  String savedDeleteHighlightMessage(String reference);
  String get savedCancel;
  String get savedNoteDeleted;
  String get savedBookmarkDeleted;
  String get savedHighlightDeleted;

  // ── Reader ────────────────────────────────────────────────────────────────
  String get chapterAbbr; // short label for chapter, e.g. "ምዕ" / "Ch"
  String get verseBookmark;
  String get verseHighlight;
  String get verseNote;
  String get verseCopy;
  String get verseShare;

  /// Title of the sheet listing a verse's parallel passages.
  String get verseCrossReferences;

  /// Title of the sheet listing a verse's translator footnotes.
  String get verseFootnotes;
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

  // ── Forgot password ───────────────────────────────────────────────────────
  String get forgotTitle;
  String get forgotSubtitle;
  String get forgotEmailLabel;
  String get forgotEmailHelper;
  String get forgotPhoneLabel;
  String get forgotPhoneHelper;
  String get forgotSendButton;
  String get forgotRememberPassword;
  String get forgotPhoneComingSoon;
  String get forgotTabPhone;

  // ── Reset password ────────────────────────────────────────────────────────
  String get resetTitle;
  String get resetSubtitle;
  String get resetTokenLabel;
  String get resetNewPasswordLabel;
  String get resetConfirmLabel;
  String get resetRequirementsTitle;
  String get resetReqLength;
  String get resetReqUpper;
  String get resetReqNumber;
  String get resetReqSpecial;
  String get resetSaveButton;
  String get resetSuccessMessage;

  // ── Profile screen ────────────────────────────────────────────────────────
  String get profileTitle;
  String get profileMemberBadge;
  String get profileLogout;
  String get profileDeleteAccount;
  String get profileEditButton;
  String get profileAchievements;
  String get profileStatStreak;
  String get profileStatBookmarks;
  String get profileStatPlan;
  String get profileDeleteTitle;
  String get profileDeleteMessage;
  String get profileDeleteCancel;
  String get profileDeleteConfirm;
  String get achievementFirstDayTitle;
  String get achievementFirstDaySub;
  String get achievement7DayTitle;
  String get achievement7DaySub;
  String get achievementPsalmTitle;
  String get achievementPsalmSub;

  // ── Profile editing ───────────────────────────────────────────────────────
  String get profileFirstName;
  String get profileLastName;
  String get profileSaveChanges;
  String get profileSaved;
  String get profileSectionInfo;
  String get profileSectionSecurity;
  String get profileSectionPreferences;
  String get profileChangePhoto;
  String get profileGoogleNote;
  String get profileChangePassword;
  String get profileCurrentPassword;
  String get profileNewPassword;
  String get profileConfirmNewPassword;
  String get profileUpdatePassword;
  String get profilePasswordChanged;
  String get profilePasswordMismatch;
  String get profileUpdateFailed;
  // ── Notifications ─────────────────────────────────────────────────────────
  String get notificationPermissionDenied;
  String dailyVerseSet(String time);
  String get dailyVerseOff;
  String dailyVerseUpdated(String time);
  String get readingReminderOff;
  String readingReminderSet(String time);
  String readingReminderUpdated(String time);

  // ── Verse card sheet ──────────────────────────────────────────────────────
  String get cardSheetTitle;
  String get cardTabBackground;
  String get cardTabText;
  String get cardTabReference;
  String get cardTabRatio;
  String get cardShare;
  String get cardSaveToGallery;
  String get cardSaved;
  String get cardSaveFailed;
  String get cardBgColours;
  String get cardBgGradients;
  String get cardBgGallery;
  String get cardBgFrame;
  String get cardFontLabel;
  String get cardSizeLabel;
  String get cardColorLight;
  String get cardColorDark;
  String get cardRefGeez;
  String get cardRefArabic;
  String get cardRefAmharic;
  String get cardRefEnglish;
  String get cardRefShow;
  // reference_picker
  String get cardRefNumeralStyle;
  String get cardRefNumeralHint;
  String get cardRefBookLang;
  String get cardRefBookLangHint;
  // text_picker
  String get cardTextColour;
  String get cardTextAlignment;
  // ratio_picker
  String get cardRatioSquare;
  String get cardRatioPortrait;
  String get cardRatioStory;
  // background_picker frame labels
  String get cardFrameNone;
  String get cardFrameSimple;
  String get cardFrameOrnate;
  String get cardFrameManuscript;
  // background_picker snackbar
  String get cardImagePickFailed;
  String get cardShareAsText;

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingDone;

  // Screen 1: Welcome
  String get onboardingWelcomeTitle;
  String get onboardingWelcomeCanonNote;

  // Screen 2: Preferences
  String get onboardingPrefsTitle;
  String get onboardingPrefsSubtitle;
  String get onboardingPreviewVerseText;

  // Screen 3: Verse actions
  String get onboardingActionsTitle;
  String get onboardingActionsSubtitle;

  // Screen 4: Sign-in
  String get onboardingSignInTitle;
  String get onboardingSignInSubtitle;
  String get onboardingSignInBtn;
  String get onboardingNotNowBtn;

  // MeScreen introduction row
  String get meShowIntroduction;

  // Reader coach mark
  String get readerVerseActionHint;
  // ── Bible editions ────────────────────────────────────────────────────────
  /// Title of the edition picker / download screen.
  String get editionsTitle;
  String get editionsSubtitle;

  /// Section headers: what is on the device vs what can be fetched.
  String get editionsInstalled;
  String get editionsAvailable;

  String get editionDownload;
  String get editionUpdate;
  String get editionRemove;
  String get editionUse;
  String get editionActive;

  /// Shown on am-2000, which ships inside the app and cannot be removed.
  String get editionBuiltIn;

  String get editionDownloading;
  String get editionRemoveTitle;
  String editionRemoveBody(String title);
  String get editionRemoveConfirm;
  String get editionCancel;
  String editionUpdated(String title);
  String editionUpToDate(String title);

  /// Copyright line naming the edition's publisher.
  String editionPublishedBy(String publisher);
  String get editionPublicDomain;

  // ── Edition chooser ───────────────────────────────────────────────────────
  /// Sheet opened from the book list, the chapter grid and the reader.
  String get editionSwitchTitle;
  String get editionSwitchSubtitle;

  /// Row at the foot of the sheet that opens the full editions screen.
  String get editionManage;
  String editionMoreAvailable(int count);
  String editionSwitched(String title);

  /// Shown when the edition just switched to does not carry the open book —
  /// the protestant canons have no deuterocanon, so this is expected.
  String editionBookMissing(String title);

  String get editionUpdateAvailable;
  String get editionsFilterAll;
  String get editionsNoneForFilter;
  String get editionsCheckUpdates;

  /// Label over the hero card on the editions screen.
  String get editionsActiveLabel;
  String editionsOnDeviceCount(int installed, int total);

  String editionMetaBooks(String count);
  String editionMetaChapters(String count);
  String editionMetaVerses(String count);

  // ── Parallel reading ──────────────────────────────────────────────────────
  /// Header over the parallel-column part of the edition chooser.
  String get parallelSectionTitle;
  String get parallelSectionSubtitle;

  /// Per-row toggle that puts an edition in the reader's second column.
  String get parallelShowAlongside;

  /// Settings row and its value when no second column is chosen.
  String get parallelSettingLabel;
  String get parallelOff;

  String parallelEnabled(String title);
  String get parallelDisabled;

  /// Shown in place of the second column when the parallel edition's canon
  /// does not carry the open book.
  String parallelBookMissing(String title);
  // in your AppStrings abstract class
  String get onboardingSampleVerseNumber;
  String get onboardingSampleVerseText;
}
