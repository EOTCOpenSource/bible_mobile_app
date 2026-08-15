import 'app_strings.dart';

class EnStrings extends AppStrings {
  const EnStrings();

  // ── Navigation ────────────────────────────────────────────────────────────
  @override
  String get navHome => 'Home';
  @override
  String get navBooks => 'Books';
  @override
  String get navSearch => 'Search';
  @override
  String get navPlans => 'Plans';
  @override
  String get navSaved => 'Collection';
  @override
  String get navMe => 'Me';

  // ── Home header ───────────────────────────────────────────────────────────
  @override
  String get welcomeGreeting => 'Welcome Back';

  // ── Reading streak ────────────────────────────────────────────────────────
  @override
  String get streakConsecutiveLabel => 'reading streak';
  @override
  String get streakDaysSuffix => 'days';
  @override
  String get streakReadTodayHint => 'Read a chapter today';
  @override
  String get streakReadTodayBtn => 'Read Now';

  // ── Streak emoji customisation ────────────────────────────────────────────
  @override
  String get streakEmojiTitle => 'Streak Emoji';
  @override
  String get streakEmojiHint => 'The emoji shown beside your reading days';
  @override
  String get streakEmojiSectionChoose => 'Choose an emoji';
  @override
  String get streakEmojiPreviewLabel => 'Preview';
  @override
  String get streakEmojiWidgetNote =>
      'Your choice also appears beside your streak inside the app.';

  // ── Home screen widgets ───────────────────────────────────────────────────
  @override
  String get sectionWidgets => 'Widgets';
  @override
  String get widgetsTitle => 'Home Screen Widgets';
  @override
  String get widgetsHint => 'Theme, text size and which rows are shown';
  @override
  String get widgetsChooseLabel => 'Choose a widget';

  @override
  String get widgetNameDailyVerse => 'Daily Verse';
  @override
  String get widgetNameContinue => 'Continue Reading';
  @override
  String get widgetNameStreak => 'Reading Streak';

  @override
  String get widgetSectionTheme => 'Theme';
  @override
  String get widgetThemeAuto => 'Auto';
  @override
  String get widgetThemeLight => 'Light';
  @override
  String get widgetThemeDark => 'Dark';
  @override
  String get widgetThemeBrand => 'Maroon';

  @override
  String get widgetSectionTextSize => 'Text size';
  @override
  String get widgetTextSmall => 'Small';
  @override
  String get widgetTextMedium => 'Medium';
  @override
  String get widgetTextLarge => 'Large';

  @override
  String get widgetSectionOpacity => 'Background opacity';
  @override
  String get widgetSectionOptions => 'Visible parts';

  @override
  String get widgetToggleVerseTag => 'Header tag';
  @override
  String get widgetToggleVerseRef => 'Reference line';
  @override
  String get widgetToggleContinueLabel => 'Label';
  @override
  String get widgetToggleProgressBar => 'Progress bar';
  @override
  String get widgetToggleStreakDays => 'Days label';
  @override
  String get widgetToggleStreakEmoji => 'Emoji';

  @override
  String get widgetEmptyVerse => 'Open the app';
  @override
  String get widgetEmptyContinue => 'Start reading';

  @override
  String get widgetAddToHome => 'Add to home screen';
  @override
  String get widgetAddUnsupported =>
      'Your launcher does not allow this. Press and hold your home screen to '
      'add the widget instead.';
  @override
  String get widgetResizeHint =>
      'Press and hold a widget on your home screen to resize it — its contents '
      'adjust to the size you give it.';
  @override
  String get widgetsAndroidOnly =>
      'Home screen widgets are available on Android only.';

  // ── Streak page ───────────────────────────────────────────────────────────
  @override
  String get streakPageTitle => 'Reading Streak';
  @override
  String get streakDayStreakLabel => 'day streak';
  @override
  String get streakStatLongest => 'Longest streak';
  @override
  String get streakStatTotalDays => 'Total days';
  @override
  String get streakStatChapters => 'Chapters';
  @override
  String streakMonthProgress(String read, String total) =>
      '$read / $total days';
  @override
  String streakFreezeTitle(String count) => '$count rest days available';
  @override
  String get streakFreezeSubtitle =>
      'A missed day is covered so your streak survives';
  @override
  String get streakFreezeEmptyTitle => 'No rest days yet';
  @override
  String get streakFreezeEmptySubtitle =>
      'Every week of reading earns one rest day';
  @override
  String get streakTodayDone => 'Read today';

  // ── Daily verse ───────────────────────────────────────────────────────────
  @override
  String get dailyVerseTag => 'Daily Verse';
  @override
  String get dailyVerseUnavailable =>
      "Today's verse couldn't be loaded. Tap to retry.";

  // ── Continue reading ──────────────────────────────────────────────────────
  @override
  String get continueReadingTitle => 'Continue Reading';
  @override
  String get startReadingTitle => 'Start Reading';
  @override
  String get startReadingAction => 'Start';
  @override
  String completedPercent(int pct) => '$pct% complete';

  // ── Reading plans ─────────────────────────────────────────────────────────
  @override
  String get readingPlansTitle => 'Reading Plans';
  @override
  String get viewAll => 'View all';
  @override
  String daysCount(int n) => '$n days';
  @override
  String get readingPlansSyncPrompt =>
      'Log in to sync your reading plans across devices';
  @override
  String get continueWithoutAccount => 'Continue without account';

  // ── Me / Settings ─────────────────────────────────────────────────────────
  @override
  String get meTitle => 'Settings';
  @override
  String get meProfileEditBadge => 'Complete Profile';

  @override
  String get sectionReading => 'Reading';
  @override
  String get sectionLanguage => 'Language';
  @override
  String get sectionNumbers => 'Numbers';
  @override
  String get sectionReminders => 'Reminders';

  @override
  String get settingTranslation => 'Default Translation';
  @override
  String get settingTranslationValue => 'Amharic';
  @override
  String get settingReadingPrefs => 'Reading Settings';
  @override
  String get settingReadingPrefsHint => 'Font, size, theme';
  @override
  String get settingNightMode => 'Night Mode';
  @override
  String get settingNightModeHint => 'Reduce eye strain';
  @override
  String get settingAudio => 'Audio Reading';
  @override
  String get settingAudioAction => 'Try';

  @override
  String get settingLanguage => 'Language';
  @override
  String get langAmharic => 'አማርኛ (Amharic)';
  @override
  String get langEnglish => 'English';

  @override
  String get settingGeezNums => 'Geez Numerals';
  @override
  String get settingGeezNumsHint => 'Use ፩፪፫ instead of 1 2 3';

  @override
  String get settingDailyVerse => 'Daily Verse Notification';
  @override
  String get settingDailyVerseHint => 'Every morning';
  @override
  String get settingReadingTime => 'Reading Time';
  @override
  String get settingReadingTimeHint => 'Set your daily reading time';

  // ── Books tab ─────────────────────────────────────────────────────────────
  @override
  String get booksTitle => 'Books';
  @override
  String get booksOldTestament => 'Old Testament';
  @override
  String get booksNewTestament => 'New Testament';
  @override
  String get booksDeuterocanonical => 'Deuterocanon';
  @override
  String booksSubtitle(String c) => '$c Books';
  @override
  String get booksFilterAll => 'All';
  @override
  String get booksFilterLaw => 'Law';
  @override
  String get booksFilterHistory => 'History';
  @override
  String get booksFilterWisdom => 'Wisdom';
  @override
  String get booksFilterProphets => 'Prophets';
  @override
  String get booksFilterOther => 'Other';
  @override
  String get booksFilterGospels => 'Gospels';
  @override
  String get booksFilterActs => 'Acts';
  @override
  String get booksFilterPauline => 'Pauline';
  @override
  String get booksFilterGeneral => 'General';
  @override
  String get booksFilterRevelation => 'Revelation';
  @override
  String get booksChapterSuffix => 'chs.';

  // ── Book Introductions ──────────────────────────────────────────────────
  @override
  String get aboutThisBook => 'About this book';
  @override
  String get author => 'Author';
  @override
  String get period => 'Period';
  @override
  String get themes => 'Themes';
  @override
  String get readMore => 'Read more';
  @override
  String get showLess => 'Show less';
  @override
  String get outline => 'Outline';

  // ── Chapter selector ──────────────────────────────────────────────────────
  @override
  String get chapSelectorLastRead => 'Where you left off';
  @override
  String get chapSelectorContinueBtn => 'Continue';
  @override
  String get chapSelectorVerseLabel => 'Vs';
  @override
  String get chapSelectorProgressSuffix => 'read';
  @override
  String get chapSelectorChapNosLabel => 'Chapter Nos.';
  @override
  String get legendCurrent => 'Now';
  @override
  String get legendNextChapter => 'Next';
  @override
  String get legendUnread => 'Unread';
  @override
  String get legendBookmark => 'Bookmarked';

  // ── Reading Settings ──────────────────────────────────────────────────────
  @override
  String get readingSettingsTitle => 'Reading Settings';
  @override
  String get readingSettingsBodyFont => 'Body Font';
  @override
  String get readingSettingsTitleFont => 'Title Font';
  @override
  String get readingSettingsFontSize => 'Font Size';
  @override
  String get readingSettingsNightMode => 'Night Mode';
  @override
  String get readingSettingsPreview => 'Preview';
  @override
  String get readingSettingsReset => 'Reset';
  @override
  String get readingSettingsContinuous => 'Continuous reading';
  @override
  String get readingSettingsLineHeight => 'Line Spacing';
  @override
  String get readingSettingsMarginScale => 'Side Margins';
  @override
  String get readingSettingsTextAlign => 'Text Alignment';
  @override
  String get readingSettingsAlignStart => 'Left';
  @override
  String get readingSettingsAlignJustify => 'Justify';
  @override
  String get readingSettingsKeepScreenOn => 'Keep Screen On';
  @override
  String get readingSettingsShowCrossRefMarkers => 'Show notes and references';
  @override
  String get readingSettingsShowCrossRefMarkersHint =>
      "Set the edition's own notes and cross-references under each verse";

  // ── Search ───────────────────────────────────────────────────────────────
  @override
  String get searchHint => 'Search the scriptures...';
  @override
  String get searchPrompt => 'Type to search';
  @override
  String get searchNoResults => 'No results found';
  @override
  String searchResultCount(int n) => '$n result${n == 1 ? '' : 's'}';
  @override
  String get searchRunBtn => 'Go';
  @override
  String get searchSmartMode => 'Smart';
  @override
  String get searchAllWords => 'All Words';
  @override
  String get searchInAll => 'In All';
  @override
  String get searchScopeTitle => 'Search Scope';
  @override
  String get searchPickBook => 'Pick a Book';
  @override
  String get searchOrPickBook => 'Or pick a book';

  // ── Saved / Collection ───────────────────────────────────────────────────
  @override
  String get savedEyebrow => 'Saved';
  @override
  String get savedTitle => 'Saved';
  @override
  String get savedHistory => 'History';
  @override
  String get savedHighlights => 'Highlights';
  @override
  String get savedBookmarks => 'Bookmarks';
  @override
  String get savedNotes => 'Notes';
  @override
  String get savedFilterAll => 'All';
  @override
  String get savedFilterOld => 'Old';
  @override
  String get savedFilterNew => 'New';
  @override
  String get savedPickBook => 'Pick a book';
  @override
  String get savedAllBooks => 'All books';
  @override
  String get savedPickChapter => 'Pick a chapter';
  @override
  String get savedAllChapters => 'All chapters';
  @override
  String get savedAllChaptersShort => 'All ch.';
  @override
  String savedChapterLabel(int chapter) => 'Ch. $chapter';
  @override
  String get savedToday => 'Today';
  @override
  String get savedYesterday => 'Yesterday';
  @override
  String savedDaysAgo(int days) => '$days day${days == 1 ? '' : 's'}';
  @override
  String get savedEmptyHighlightsTitle => 'No highlights yet';
  @override
  String get savedEmptyHighlightsHint => 'Highlight verses while reading';
  @override
  String get savedEmptyBookmarksTitle => 'No bookmarks yet';
  @override
  String get savedEmptyBookmarksHint => 'Bookmark verses while reading';
  @override
  String get savedEmptyNotesTitle => 'No Notes';
  @override
  String get savedEmptyNotesHint => 'Tap a verse and select "Note" to write down your thoughts. They will appear here.';
  @override
  String get savedClearHistory => 'Clear History';
  @override
  String get savedClearHistoryTitle => 'Clear Reading History?';
  @override
  String get savedClearHistoryMessage => 'This will remove all your reading history. This action cannot be undone.';
  @override
  String get savedEdit => 'Edit';
  @override
  String get savedDelete => 'Delete';
  @override
  String get savedDeleteNoteTitle => 'Delete note';
  @override
  String savedDeleteNoteMessage(String reference) =>
      'Do you want to delete this note?\n$reference';
  @override
  String get savedDeleteBookmarkTitle => 'Delete bookmark';
  @override
  String savedDeleteBookmarkMessage(String reference) =>
      'Delete this bookmark?\n$reference';
  @override
  String get savedDeleteHighlightTitle => 'Delete highlight';
  @override
  String savedDeleteHighlightMessage(String reference) =>
      'Delete this highlight?\n$reference';
  @override
  String get savedCancel => 'Cancel';
  @override
  String get savedNoteDeleted => 'Note deleted';
  @override
  String get savedBookmarkDeleted => 'Bookmark deleted';
  @override
  String get savedHighlightDeleted => 'Highlight deleted';
  @override
  String get timeMorning => 'AM';
  @override
  String get timeAfternoon => 'PM';
  @override
  String get historyEmptyHint => 'Start reading to see history here';
  @override
  String get loadMore => 'Load more';
  @override
  String get savedDeleteHistoryTitle => 'Remove this from history?';
  @override
  String get collections => 'Collections';
  @override
  String get newCollection => 'New collection';
  @override
  String get addToCollection => 'Add to collection';
  @override
  String get collectionSubtitle =>
      'Organize this item into one or more collections.';
  @override
  String get collectionSearchHint => 'Search or create collection...';
  @override
  String createNamedCollection(String name) => 'Create "$name"';
  @override
  String get recentCollections => 'Recent Collections';
  @override
  String get allCollections => 'All Collections';
  @override
  String get noCollectionsEmptyHint =>
      'Start typing to create your first collection.';
  @override
  String get noCollectionsFound => 'No collections found';
  @override
  String get tags => 'Tags';
  @override
  String get addTags => 'Add tags';
  @override
  String get all => 'All';
  @override
  String get noCollections => 'No collections yet';
  @override
  String get addTagHint => 'Add tag (press comma or Enter)...';
  @override
  String get collectionNameHint => 'Collection name';
  @override
  String get collectionColorLabel => 'Color';
  @override
  String get collectionCreateAction => 'Create';
  @override
  String get savedOk => 'OK';
  @override
  String get collectionDeleteTitle => 'Delete collection';
  @override
  String get collectionDeleteMessage =>
      'This collection will be removed. The notes, highlights and bookmarks '
      'inside it are not deleted.';
  @override
  String selectedCount(int count) => '$count selected';
  @override
  String get deleteSelectedTitle => 'Delete Selected';
  @override
  String deleteSelectedMessage(int count) =>
      'Are you sure you want to delete $count selected item(s)?';

  // ── Reader ────────────────────────────────────────────────────────────────
  @override
  String get chapterAbbr => 'Ch';
  @override
  String get verseBookmark => 'Bookmark';
  @override
  String get verseHighlight => 'Highlight';
  @override
  String get verseNote => 'Note';
  @override
  String get verseCopy => 'Copy';
  @override
  String get verseShare => 'Share';
  @override
  String get verseCrossReferences => 'Similar';
  @override
  String get verseReference => 'Reference';
  @override
  String get crossRefTitle => 'Cross-References';
  @override
  String crossRefCount(int n) => n == 1 ? '1 reference' : '$n references';
  @override
  String get crossRefNoResults => 'No cross-references for this verse';
  @override
  String crossRefBackTo(String reference) => '← Back to $reference';
  @override
  String get verseFootnotes => 'Footnotes';
  @override
  String get comingSoon => 'Coming soon';

  // ── Auth — shared ─────────────────────────────────────────────────────────
  @override
  String get authEmail => 'Email';
  @override
  String get authEmailRequired => 'Email is required';
  @override
  String get authEmailInvalid => 'Enter a valid email';
  @override
  String get authPassword => 'Password';
  @override
  String get authPasswordRequired => 'Password is required';
  @override
  String get authConnectionError => 'Connection failed. Please try again.';

  // ── Auth — login ──────────────────────────────────────────────────────────
  @override
  String get loginTitle => 'Welcome Back';
  @override
  String get loginSubtitle => 'Sign in to continue reading the Holy Word.';
  @override
  String get loginRememberMe => 'Remember me';
  @override
  String get loginForgotPassword => 'Forgot password?';
  @override
  String get loginButton => 'Sign In';
  @override
  String get loginOrDivider => 'Or sign in with';
  @override
  String get loginNoAccount => "Don't have an account? ";
  @override
  String get loginRegisterLink => 'Register';
  @override
  String get loginVerseQuote => 'Your word is a lamp forever';
  @override
  String get loginAccountLocked => 'Account locked. Try again in 2 hours.';
  @override
  String get loginGoogleFailed => 'Google sign-in failed. Try again.';
  @override
  String get loginFacebookComingSoon => 'Facebook Sign In — Coming soon';

  // ── Auth — register ───────────────────────────────────────────────────────
  @override
  String get registerTitle => 'Create Account';
  @override
  String get registerSubtitle => 'Save your progress, highlights, and notes.';
  @override
  String get registerFullName => 'Full Name';
  @override
  String get registerFullNameRequired => 'Full name is required';
  @override
  String get registerFullNameTooShort => 'Name must be at least 2 characters';
  @override
  String get registerPasswordTooShort => 'At least 8 characters required';
  @override
  String get registerAcceptTerms => 'Please accept the terms and conditions';
  @override
  String get registerButton => 'Register';
  @override
  String get registerHaveAccount => 'Already have an account? ';
  @override
  String get registerLoginLink => 'Sign In';
  @override
  String get registerTermsText =>
      'I accept the Community Terms and Privacy Policy.';
  @override
  String get passwordWeak => 'Weak';
  @override
  String get passwordFair => 'Fair';
  @override
  String get passwordGood => 'Good';
  @override
  String get passwordStrong => 'Strong';

  // ── Auth — OTP ────────────────────────────────────────────────────────────
  @override
  String get otpTitle => 'Verify Your Code';
  @override
  String get otpSentPrefix => 'We sent a 6-digit code to ';
  @override
  String get otpSentSuffix => '. Enter it below.';
  @override
  String otpDigitsRequired(int n) => '$n-digit code required';
  @override
  String get otpNotReceived => "Didn't receive the code? ";
  @override
  String otpResendIn(String t) => 'Resend in $t';
  @override
  String get otpResend => 'Resend';
  @override
  String get otpVerifyButton => 'Verify';
  @override
  String get otpChangePhone => 'Change phone number';
  @override
  String get otpChangeEmail => 'Change email';
  @override
  String get otpResendFailed => 'Failed to resend. Try again.';

  // ── Forgot password ───────────────────────────────────────────────────────
  @override
  String get forgotTitle => 'Forgot Password?';
  @override
  String get forgotSubtitle =>
      'No worries. Enter your registered email and we\'ll send a reset code.';
  @override
  String get forgotEmailLabel => 'Registered Email';
  @override
  String get forgotEmailHelper => 'A reset code will be sent to this email.';
  @override
  String get forgotPhoneLabel => 'Registered Phone Number';
  @override
  String get forgotPhoneHelper =>
      'A reset code will be sent to this phone number.';
  @override
  String get forgotSendButton => 'Send Code';
  @override
  String get forgotRememberPassword => 'Remember your password? ';
  @override
  String get forgotPhoneComingSoon => 'Phone reset — coming soon';
  @override
  String get forgotTabPhone => 'Phone';

  // ── Reset password ────────────────────────────────────────────────────────
  @override
  String get resetTitle => 'New Password';
  @override
  String get resetSubtitle => 'Choose a strong password you\'ll remember.';
  @override
  String get resetTokenLabel => 'Code from your email';
  @override
  String get resetNewPasswordLabel => 'New Password';
  @override
  String get resetConfirmLabel => 'Confirm Password';
  @override
  String get resetRequirementsTitle => 'Password Requirements';
  @override
  String get resetReqLength => 'At least 8 characters';
  @override
  String get resetReqUpper => 'One uppercase letter (A–Z)';
  @override
  String get resetReqNumber => 'One number (0–9)';
  @override
  String get resetReqSpecial => 'One special character (!@#\$)';
  @override
  String get resetSaveButton => 'Save and Sign In';
  @override
  String get resetSuccessMessage => 'Password changed. Please sign in.';

  // ── Profile screen ────────────────────────────────────────────────────────
  @override
  String get profileTitle => 'Profile';
  @override
  String get profileSignedOut => 'You are signed out';
  @override
  String get profileMemberBadge => 'Member';
  @override
  String get profileLogout => 'Sign Out';
  @override
  String get profileDeleteAccount => 'Delete Account';
  @override
  String get profileEditButton => 'Edit Profile';
  @override
  String get profileAchievements => 'Achievements';
  @override
  String get profileStatStreak => 'Day Streak';
  @override
  String get profileStatBookmarks => 'Marks';
  @override
  String get profileStatPlan => 'Plan';
  @override
  String get profileDeleteTitle => 'Delete Account?';
  @override
  String get profileDeleteMessage =>
      'All your data will be lost. This cannot be undone.';
  @override
  String get profileDeleteCancel => 'Cancel';
  @override
  String get profileDeleteConfirm => 'Delete';
  @override
  String get achievementFirstDayTitle => 'First Day';
  @override
  String get achievementFirstDaySub => 'First Day';
  @override
  String get achievement7DayTitle => '7-Day Streak';
  @override
  String get achievement7DaySub => '7-Day Streak';
  @override
  String get achievementPsalmTitle => 'Psalm Reader';
  @override
  String get achievementPsalmSub => 'Psalm Reader';

  // ── Profile editing ───────────────────────────────────────────────────────
  @override
  String get profileFirstName => 'First Name';
  @override
  String get profileLastName => 'Last Name';
  @override
  String get profileSaveChanges => 'Save Changes';
  @override
  String get profileSaved => 'Profile updated';
  @override
  String get profileSectionInfo => 'Account Info';
  @override
  String get profileSectionSecurity => 'Security';
  @override
  String get profileSectionPreferences => 'Preferences';
  @override
  String get profileChangePhoto => 'Change Photo';
  @override
  String get profileGoogleNote =>
      'Signed in with Google — email cannot be changed';
  @override
  String get profileChangePassword => 'Change Password';
  @override
  String get profileCurrentPassword => 'Current Password';
  @override
  String get profileNewPassword => 'New Password';
  @override
  String get profileConfirmNewPassword => 'Confirm New Password';
  @override
  String get profileUpdatePassword => 'Update Password';
  @override
  String get profilePasswordChanged => 'Password changed successfully';
  @override
  String get profilePasswordMismatch => 'Passwords do not match';
  @override
  String get profileUpdateFailed => 'Update failed. Please try again.';

  // ── Verse card sheet ──────────────────────────────────────────────────────
  @override
  String get cardSheetTitle => 'Design & Share';
  @override
  String get cardTabBackground => 'Background';
  @override
  String get cardTabText => 'Text';
  @override
  String get cardTabReference => 'Reference';
  @override
  String get cardTabRatio => 'Size';
  @override
  String get cardShare => 'Share';
  @override
  String get cardSaveToGallery => 'Save';
  @override
  String get cardSaved => 'Saved to gallery';
  @override
  String get cardSaveFailed => 'Failed to save';
  @override
  String get cardBgColours => 'Colours';
  @override
  String get cardBgGradients => 'Gradients';
  @override
  String get cardBgGallery => 'Gallery';
  @override
  String get cardBgFrame => 'Frame';
  @override
  String get cardFontLabel => 'Font';
  @override
  String get cardSizeLabel => 'Size';
  @override
  String get cardColorLight => 'Light';
  @override
  String get cardColorDark => 'Dark';
  @override
  String get cardRefGeez => 'Geez';
  @override
  String get cardRefArabic => '123';
  @override
  String get cardRefAmharic => 'Amharic';
  @override
  String get cardRefEnglish => 'English';
  @override
  String get cardRefShow => 'Show reference';
  @override
  String get cardRefNumeralStyle => 'Numeral Style';
  @override
  String get cardRefNumeralHint => 'Choose numeral system';
  @override
  String get cardRefBookLang => 'Book Name Language';
  @override
  String get cardRefBookLangHint => 'Display language of source book';
  @override
  String get cardTextColour => 'Colour';
  @override
  String get cardTextAlignment => 'Alignment';
  @override
  String get cardRatioSquare => 'Square';
  @override
  String get cardRatioPortrait => 'Portrait (Tall)';
  @override
  String get cardRatioStory => 'Story / Status';
  @override
  String get cardFrameNone => 'None';
  @override
  String get cardFrameSimple => 'Simple';
  @override
  String get cardFrameOrnate => 'Ornate';
  @override
  String get cardFrameManuscript => 'Manuscript';
  @override
  String get cardImagePickFailed => 'Failed to pick image';
  @override
  String get cardShareAsText => 'Share as text';

  // ── Notifications ─────────────────────────────────────────────────────────
  @override
  String get notificationPermissionDenied => 'Notification permission denied';
  @override
  String dailyVerseSet(String time) => '✓ Daily verse set for $time';
  @override
  String get dailyVerseOff => 'Daily verse reminder off';
  @override
  String dailyVerseUpdated(String time) => '✓ Daily verse updated to $time';
  @override
  String get readingReminderOff => 'Reading reminder off';
  @override
  String readingReminderSet(String time) => '✓ Reading reminder set for $time';
  @override
  String readingReminderUpdated(String time) =>
      '✓ Reading reminder updated to $time';

  // ── Onboarding ────────────────────────────────────────────────────────────
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingDone => 'Get Started';

  @override
  String get onboardingWelcomeTitle => 'Holy Bible';
  @override
  String get onboardingWelcomeCanonNote =>
      'The 81-book Ethiopian Orthodox Tewahedo Church biblical canon.';

  @override
  String get onboardingPrefsTitle => 'Reading Preferences';
  @override
  String get onboardingPrefsSubtitle =>
      'Customize your font size, language, and numeral system.';
  @override
  String get onboardingPreviewVerseText =>
      'In the beginning was the Word, and the Word was with God, and the Word was God. (John 1:1)';

  @override
  String get onboardingActionsTitle => 'Verse Actions';
  @override
  String get onboardingActionsSubtitle =>
      'Tap verses to highlight, write notes, bookmark, or share.';

  @override
  String get onboardingSignInTitle => 'Optional Sign In';
  @override
  String get onboardingSignInSubtitle =>
      'Sign in to sync your notes and bookmarks across devices. The app works fully offline without an account.';
  @override
  String get onboardingSignInBtn => 'Sign in';
  @override
  String get onboardingNotNowBtn => 'Not now';
  @override
  String get onboardingSampleVerseNumber => '1';

  @override
  String get onboardingSampleVerseText =>
      'In the beginning was the Word, and the Word was with God, and the Word was God.';

  @override
  String get meShowIntroduction => 'Show introduction';

  @override
  String get readerVerseActionHint =>
      'Tap a verse to highlight, note, bookmark, or share';
  @override
  String get editionsTitle => 'Bible editions';
  @override
  String get editionsSubtitle => 'Choose an edition or download another';
  @override
  String get editionsInstalled => 'On this device';
  @override
  String get editionsAvailable => 'Available to download';
  @override
  String get editionDownload => 'Download';
  @override
  String get editionUpdate => 'Update';
  @override
  String get editionRemove => 'Remove';
  @override
  String get editionUse => 'Use';
  @override
  String get editionActive => 'Active';
  @override
  String get editionBuiltIn => 'Built in';
  @override
  String get editionDownloading => 'Downloading…';
  @override
  String get editionRemoveTitle => 'Remove this edition?';
  @override
  String editionRemoveBody(String title) =>
      '$title will be deleted from this device. Your notes and highlights are '
      'kept, and you can download it again at any time.';
  @override
  String get editionRemoveConfirm => 'Remove';
  @override
  String get editionCancel => 'Cancel';
  @override
  String editionUpdated(String title) => '$title updated';
  @override
  String editionUpToDate(String title) => '$title is up to date';
  @override
  String editionPublishedBy(String publisher) => 'Published by $publisher';
  @override
  String get editionPublicDomain => 'Public domain';
  @override
  String get editionSwitchTitle => 'Choose an edition';
  @override
  String get editionSwitchSubtitle => 'Switch the text you are reading';
  @override
  String get editionManage => 'Manage editions';
  @override
  String editionMoreAvailable(int count) => '$count more to download';
  @override
  String editionSwitched(String title) => 'Now reading $title';
  @override
  String editionBookMissing(String title) => 'This book is not part of $title';
  @override
  String get editionUpdateAvailable => 'Update available';
  @override
  String get editionsFilterAll => 'All';
  @override
  String get editionsNoneForFilter => 'No editions in this language';
  @override
  String get editionsCheckUpdates => 'Check for updates';
  @override
  String get editionsActiveLabel => 'Currently reading';
  @override
  String editionsOnDeviceCount(int installed, int total) =>
      '$installed of $total on this device';
  @override
  String editionMetaBooks(String count) => '$count books';
  @override
  String editionMetaChapters(String count) => '$count chapters';
  @override
  String editionMetaVerses(String count) => '$count verses';

  // ── Audio reading ──────────────────────────────────────────────────────────
  @override
  String get voiceSettingsTitle => 'Reading Voice';
  @override
  String get voiceSectionKey => 'Addis AI key';
  @override
  String get voiceSectionVoices => 'Choose a voice';
  @override
  String get voiceKeyIntro =>
      'Audio reading is powered by Addis AI. Get your own key from Addis AI '
      'and paste it here — it stays on this device.';
  @override
  String get voiceKeyGetOne => 'Get a key';
  @override
  String get voiceKeyLinkCopied => 'Link copied';
  @override
  String get voiceKeyFieldHint => 'Paste your key here';
  @override
  String get voiceKeySave => 'Save';
  @override
  String get voiceKeySaved => 'Key saved';
  @override
  String get voiceKeyChange => 'Change key';
  @override
  String get voiceKeyRemove => 'Remove key';
  @override
  String get voiceKeyRemoved => 'Key removed';
  @override
  String get voiceKeyRejected => 'That key was rejected. Please check it.';
  @override
  String get voiceKeyRequired => 'Add your key first to listen.';
  @override
  String get voiceLoadFailed => 'Could not load the voice list.';
  @override
  String get voiceListEmpty => 'No voices available for this language.';
  @override
  String get voiceRetry => 'Try again';
  @override
  String get voicePreview => 'Preview';
  @override
  String get voiceSelectedBadge => 'Selected';
  @override
  String get voiceDefaultBadge => 'Default';
  @override
  String get voiceGenderMale => 'Male';
  @override
  String get voiceGenderFemale => 'Female';
  @override
  String voiceSelectedToast(String name) => '$name selected';

  // ── Parallel reading ──────────────────────────────────────────────────────
  @override
  String get parallelSectionTitle => 'Parallel reading';
  @override
  String get parallelSectionSubtitle => 'Read two translations side by side';
  @override
  String get parallelShowAlongside => 'Show alongside';
  @override
  String get parallelSettingLabel => 'Parallel translation';
  @override
  String get parallelOff => 'Off';
  @override
  String parallelEnabled(String title) => 'Showing $title alongside';
  @override
  String get parallelDisabled => 'Parallel reading turned off';
  @override
  String parallelBookMissing(String title) =>
      'This book is not available in the $title translation';

  // ── Backup & Restore ──────────────────────────────────────────────────────
  @override
  String get sectionBackup => 'Backup';
  @override
  String get backupExportJson => 'Export backup';
  @override
  String get backupExportJsonHint => 'Generates JSON backup file';
  @override
  String get backupExportMarkdown => 'Export as Markdown';
  @override
  String get backupExportMarkdownHint => 'Human-readable export (non-importable)';
  @override
  String get backupImport => 'Import backup';
  @override
  String get backupImportHint => 'Restore annotations from JSON backup';
  @override
  String get backupMarkdownDisclaimer => 'This file cannot be re-imported';
  @override
  String get backupMarkdownBody =>
      'Your bookmarks, highlights and notes are written out as a plain document you can read, print or keep.';
  @override
  String get backupConfirmExport => 'Export';
  @override
  String get backupConflictSkip => 'Skip existing';
  @override
  String get backupConflictMerge => 'Merge';
  @override
  String get backupConflictReplace => 'Replace';
  @override
  String get backupConflictTitle => 'Conflict Resolution Policy';
  @override
  String get backupCancel => 'Cancel';
  @override
  String get backupConfirmImport => 'Import';
  @override
  String backupPreviewText(int b, int h, int n, int existing) =>
      '$b bookmarks, $h highlights, $n notes — $existing already exist';
  @override
  String get backupImportSuccess => 'Backup imported successfully';
  @override
  String get backupImportFailed => 'Import failed — file may be corrupted';
  @override
  String get backupExportSuccess => 'Backup exported successfully';
  @override
  String get backupNoFilePicked => 'No backup file selected';

  // ── Local Web Reader ──────────────────────────────────────────────────────
  @override
  String get sectionDevice => 'Device';
  @override
  String get webReaderTitle => 'Local Web Reader';
  @override
  String get webReaderHint => 'Read on your computer';
  @override
  String get webReaderStart => 'Start';
  @override
  String get webReaderStop => 'Stop';
  @override
  String get webReaderStarting => 'Starting…';
  @override
  String get webReaderRunningHint =>
      'Open this address in a browser on the same WiFi';
  @override
  String get webReaderBackgroundHint =>
      'Keeps serving when you leave the app. Stop it from the notification.';
  @override
  String get webReaderCopy => 'Copy';
  @override
  String get webReaderCopied => 'Address copied';
  @override
  String get webReaderScanHint => 'Tap to enlarge';
  @override
  String get webReaderQrTitle => 'Scan with a camera';
  @override
  String get webReaderClose => 'Close';
  @override
  String get webReaderNoNetwork =>
      'Not connected to WiFi — join a network first.';
  @override
  String get webReaderNoPort => 'The port is in use by another app.';

  // ── Fasting Calendar ───────────────────────────────────────────────────────
  @override
  String get fastingCalendarTitle => 'Fasting Calendar';
  @override
  String get fastingIsFast => 'Fast Day';
  @override
  String get fastingNotFast => 'Not a Fast Day';
  @override
  String get fastingNextFast => 'Next Fast';
  @override
  String get fastingLegendTitle => 'Fasting Types';
  @override
  String fastingDaysRemaining(String days) => '$days day${days == '1' || days == '፩' ? '' : 's'} remaining';
  @override
  String fastingStartsIn(String days) => 'in $days day${days == '1' || days == '፩' ? '' : 's'}';

  @override
  String get fastNameNebiyat => 'Fast of the Prophets';
  @override
  String get fastNameGahad => 'Fast of Gahad';
  @override
  String get fastNameNenewe => 'Fast of Nineveh';
  @override
  String get fastNameAbiyTsom => 'Great Lent';
  @override
  String get fastNameHawariyat => 'Fast of the Apostles';
  @override
  String get fastNameFilseta => 'Fast of the Assumption';
  @override
  String get fastNameDihnet => 'Fast of Salvation';
}

