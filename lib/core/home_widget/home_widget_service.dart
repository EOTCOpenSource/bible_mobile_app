import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:kenat/kenat.dart';

import '../../features/books/data/models/book_index_entry.dart';
import '../../features/books/data/reading_models.dart';
import '../../features/books/data/repositories/bible_repository.dart';
import '../deep_links/deep_link_uri.dart';
import '../l10n/app_strings.dart';
import 'home_widget_data.dart';

/// The Kotlin `AppWidgetProvider` each widget is updated through.
///
/// Fully qualified because the launcher resolves the receiver by class name,
/// and an unqualified name only works when the widget lives in the same
/// package as `MainActivity` — which is a coincidence, not a guarantee.
const _kAndroidPackage = 'org.nehemiah_osc.bible';
const _kDailyVerseProvider = '$_kAndroidPackage.widgets.DailyVerseWidget';
const _kContinueProvider = '$_kAndroidPackage.widgets.ContinueReadingWidget';
const _kStreakProvider = '$_kAndroidPackage.widgets.StreakWidget';

/// How much verse text the medium (4×2) widget can show before the launcher
/// clips it mid-word. Truncating here rather than in the layout keeps the
/// ellipsis on a word boundary, which `android:ellipsize` cannot do.
const _kVerseCharBudget = 180;

/// Pushes app state into the Android home screen widgets.
///
/// One-way and best-effort by design. A widget that fails to update shows the
/// previous day's verse, which is a far better failure than a crash on a code
/// path that runs during startup — so every entry point here swallows its
/// errors and reports them to the log only.
class HomeWidgetService {
  const HomeWidgetService._();

  /// True on the only platform that currently has widgets.
  ///
  /// Guarded rather than assumed: `home_widget` throws `MissingPluginException`
  /// on desktop and the widget tests run on the Flutter test binding, where
  /// there is no plugin at all.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Writes [data] to the shared preferences the widgets read, then asks each
  /// provider to redraw.
  static Future<void> push(HomeWidgetData data) async {
    if (!isSupported) return;
    try {
      for (final entry in data.toWidgetEntries().entries) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }
      await Future.wait([
        HomeWidget.updateWidget(qualifiedAndroidName: _kDailyVerseProvider),
        HomeWidget.updateWidget(qualifiedAndroidName: _kContinueProvider),
        HomeWidget.updateWidget(qualifiedAndroidName: _kStreakProvider),
      ]);
    } catch (e) {
      debugPrint('[HomeWidget] update failed: $e');
    }
  }
}

/// Builds the widget payload from already-resolved app state.
///
/// A pure function taking plain values rather than a method reaching into
/// repositories: every localisation and numeral rule the widgets depend on is
/// then testable without a database, a plugin or a widget tree.
///
/// [dailyVerse] and [continueReading] are null when there is nothing to show —
/// a fresh install has no reading history, and the daily verse can fail to
/// resolve offline.
HomeWidgetData buildHomeWidgetData({
  required AppStrings s,
  required bool useGeezNumbers,
  required bool isAmharic,
  required String streakEmoji,
  required DailyVerseResult? dailyVerse,
  required ({BookIndexEntry entry, ReadingPosition position, int progress})?
      continueReading,
  required int streakCount,
}) {
  String num_(int n) => useGeezNumbers ? toGeez(n) : '$n';

  final verseText = dailyVerse == null
      ? ''
      : _truncateOnWordBoundary(dailyVerse.text, _kVerseCharBudget);
  final verseRef = dailyVerse == null
      ? ''
      : '${isAmharic ? dailyVerse.bookNameAm : dailyVerse.bookNameEn} '
          '${num_(dailyVerse.chapter)}:${num_(dailyVerse.verse)}';
  final verseDeepLink = dailyVerse == null
      ? ''
      : verseDeepLinkUri(
          dailyVerse.bookEntry,
          dailyVerse.chapter,
          dailyVerse.verse,
        ).toString();

  final continueBook = continueReading == null
      ? ''
      : (isAmharic
          ? continueReading.entry.bookNameAm
          : continueReading.entry.bookNameEn);
  final continueRef = continueReading == null
      ? ''
      : '${s.booksChapterSuffix} ${num_(continueReading.position.chapter)}';

  // The reader stores a verse only once you have scrolled; chapter 1 with no
  // verse is a book that was opened and not read. Link to verse 1 so the deep
  // link is still well-formed — the reader lands at the top either way.
  final continueDeepLink = continueReading == null
      ? ''
      : verseDeepLinkUri(
          continueReading.entry,
          continueReading.position.chapter,
          continueReading.position.verse ?? 1,
        ).toString();

  return HomeWidgetData(
    verseText: verseText,
    verseRef: verseRef,
    verseDeepLink: verseDeepLink,
    continueBook: continueBook,
    continueRef: continueRef,
    continueProgress: continueReading?.progress ?? 0,
    continueDeepLink: continueDeepLink,
    streakCount: streakCount,
    streakCountLabel: num_(streakCount),
    streakEmoji: streakEmoji,
    streakSuffix: s.streakDaysSuffix,
    streakDeepLink: appRouteUri(AppRoute.streak).toString(),
  );
}

/// Cuts [text] to at most [budget] characters without splitting a word.
///
/// Falls back to a hard cut when the first word is longer than the budget,
/// which no Amharic verse hits but a malformed row could.
String _truncateOnWordBoundary(String text, int budget) {
  final trimmed = text.trim();
  if (trimmed.length <= budget) return trimmed;
  final cut = trimmed.lastIndexOf(RegExp(r'\s'), budget);
  if (cut <= 0) return '${trimmed.substring(0, budget)}…';
  return '${trimmed.substring(0, cut)}…';
}
