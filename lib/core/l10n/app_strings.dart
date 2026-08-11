/// Abstract contract for all user-facing strings.
/// Add a new getter/method here, then implement it in
/// [AmStrings] and [EnStrings].
abstract class AppStrings {
  const AppStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navHome;
  String get navBooks;
  String get navSearch;
  String get navPlans;
  String get navSaved;
  String get navMe;

  // ── Home header ───────────────────────────────────────────────────────────
  String get welcomeGreeting;

  // ── Reading streak ────────────────────────────────────────────────────────
  String get streakConsecutiveLabel;
  String get streakDaysSuffix;
  String get streakReadTodayHint;
  String get streakReadTodayBtn;

  // ── Streak page ───────────────────────────────────────────────────────────
  String get streakPageTitle;
  String get streakDayStreakLabel;
  String get streakStatLongest;
  String get streakStatTotalDays;
  String get streakStatChapters;

  /// e.g. "18 / 30 days" under the month name.
  String streakMonthProgress(String read, String total);

  /// e.g. "2 rest days available".
  String streakFreezeTitle(String count);
  String get streakFreezeSubtitle;
  String get streakFreezeEmptyTitle;
  String get streakFreezeEmptySubtitle;
  String get streakTodayDone;

  // ── Daily verse ───────────────────────────────────────────────────────────
  String get dailyVerseTag;
  String get dailyVerseUnavailable;

  // ── Continue reading ──────────────────────────────────────────────────────
  String get continueReadingTitle;

  /// Heading for the shelf shown before anything has been read.
  String get startReadingTitle;

  /// The call to action on a suggested book.
  String get startReadingAction;
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

  // ── Book Introductions ──────────────────────────────────────────────────
  String get aboutThisBook;
  String get author;
  String get period;
  String get themes;
  String get readMore;
  String get showLess;
  String get outline;

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
  String get readingSettingsLineHeight;
  String get readingSettingsMarginScale;
  String get readingSettingsTextAlign;
  String get readingSettingsAlignStart;
  String get readingSettingsAlignJustify;
  String get readingSettingsKeepScreenOn;

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
  String get savedHistory;
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
  String get savedClearHistory;
  String get savedClearHistoryTitle;
  String get savedClearHistoryMessage;
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
  String get timeMorning;
  String get timeAfternoon;
  String get historyEmptyHint;
  String get loadMore;
  String get savedDeleteHistoryTitle;
  String get collections;
  String get newCollection;
  String get addToCollection;
  String get collectionSubtitle;
  String get collectionSearchHint;
  String createNamedCollection(String name);
  String get recentCollections;
  String get allCollections;
  String get noCollectionsEmptyHint;
  String get noCollectionsFound;
  String get tags;
  String get addTags;
  String get all;
  String get noCollections;
  String get addTagHint;
  String get collectionNameHint;
  String get collectionColorLabel;
  String get collectionCreateAction;
  String get savedOk;
  String get collectionDeleteTitle;
  String get collectionDeleteMessage; // reassures that annotations survive
  String selectedCount(int count);
  String get deleteSelectedTitle;
  String deleteSelectedMessage(int count);

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
  String get profileSignedOut;
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

  // Audio reading — voice chooser and the user's own Addis AI key
  String get voiceSettingsTitle;
  String get voiceSectionKey;
  String get voiceSectionVoices;
  String get voiceKeyIntro;
  String get voiceKeyGetOne;
  String get voiceKeyLinkCopied;
  String get voiceKeyFieldHint;
  String get voiceKeySave;
  String get voiceKeySaved;
  String get voiceKeyChange;
  String get voiceKeyRemove;
  String get voiceKeyRemoved;
  String get voiceKeyRejected;
  String get voiceKeyRequired;
  String get voiceLoadFailed;
  String get voiceListEmpty;
  String get voiceRetry;
  String get voicePreview;
  String get voiceSelectedBadge;
  String get voiceDefaultBadge;
  String get voiceGenderMale;
  String get voiceGenderFemale;
  String voiceSelectedToast(String name);

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
  String get onboardingSampleVerseNumber;
  String get onboardingSampleVerseText;

  // ── Backup & Restore ──────────────────────────────────────────────────────
  String get sectionBackup;
  String get backupExportJson;
  String get backupExportJsonHint;
  String get backupExportMarkdown;
  String get backupExportMarkdownHint;
  String get backupImport;
  String get backupImportHint;
  String get backupMarkdownDisclaimer;
  String get backupMarkdownBody;
  String get backupConfirmExport;
  String get backupConflictSkip;
  String get backupConflictMerge;
  String get backupConflictReplace;
  String get backupConflictTitle;
  String get backupCancel;
  String get backupConfirmImport;
  String backupPreviewText(int b, int h, int n, int existing);
  String get backupImportSuccess;
  String get backupImportFailed;
  String get backupExportSuccess;
  String get backupNoFilePicked;

  // ── Local Web Reader ──────────────────────────────────────────────────────
  String get sectionDevice;
  String get webReaderTitle;
  String get webReaderHint;
  String get webReaderStart;
  String get webReaderStop;
  String get webReaderStarting;
  String get webReaderRunningHint;

  /// Reassures the user that leaving the app will not stop the server.
  String get webReaderBackgroundHint;
  String get webReaderCopy;
  String get webReaderCopied;
  String get webReaderScanHint;
  String get webReaderQrTitle;
  String get webReaderClose;

  /// Shown when the device has no LAN address to serve on.
  String get webReaderNoNetwork;

  /// Shown when every candidate port was already taken.
  String get webReaderNoPort;

  // ── Accessibility ────────────────────────────────────────────────────────
  String get semanticsMenuBtn;
  String get semanticsAudioBtn;
  String semanticsChapterPickerBtn(String chapterLabel);
  String get semanticsRefJumpBtn;
  String get semanticsSearchBtn;
  String get semanticsFontSettingsBtn;

  String get semanticsBookmarkAdd;
  String get semanticsBookmarkRemove;
  String get semanticsNoteAdd;
  String get semanticsNoteEdit;
  String get semanticsHighlightAdd;
  String get semanticsHighlightActive;
  String get semanticsFootnotes;

  String semanticsTabAnnouncement(String tabName, int index, int total);
  String semanticsVerseLabel(String verseNum, String text);

  String get semanticsDailyVerseShare;
  String get semanticsDailyVerseCopy;
  String semanticsContinueReading(String title);
  String semanticsStartReading(String title);
  String get semanticsStreakCard;
}
