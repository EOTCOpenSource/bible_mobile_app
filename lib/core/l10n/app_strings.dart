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
  String get streakConsecutiveLabel;   // "ተከታታይ ንባብ" / "reading streak"
  String get streakDaysSuffix;         // "ቀናት" / "days"
  String get streakReadTodayHint;      // "ዛሬ ምዕራፍ ፲ ያንብቡ" / "Read a chapter today"
  String get streakReadTodayBtn;       // "ዛሬ ያንብቡ" / "Read Now"

  /// One-letter weekday abbreviations, Sunday=0 through Saturday=6.
  List<String> get weekdayAbbr;

  // ── Daily verse ───────────────────────────────────────────────────────────
  String get dailyVerseTag;            // "የዕለቱ ቃል" / "Daily Verse"

  // ── Continue reading ──────────────────────────────────────────────────────
  String get continueReadingTitle;     // "ንባብ ቀጥል" / "Continue Reading"
  String completedPercent(int pct);    // "፵% ተጠናቅቋ" / "40% complete"

  // ── Reading plans ─────────────────────────────────────────────────────────
  String get readingPlansTitle;        // "የንባብ ዕቅዶ" / "Reading Plans"
  String get viewAll;                  // "ሁሉንም ይመልከቱ" / "View all"
  String daysCount(int n);             // "30 ቀናት" / "30 days"
}
