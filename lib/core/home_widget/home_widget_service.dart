import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:kenat/kenat.dart';

import '../../features/books/data/models/book_index_entry.dart';
import '../../features/books/data/reading_models.dart';
import '../../features/books/data/repositories/bible_repository.dart';
import '../deep_links/deep_link_uri.dart';
import '../l10n/app_strings.dart';
import '../l10n/verse_ref.dart';
import 'home_widget_data.dart';
import 'widget_appearance.dart';

/// The Kotlin `AppWidgetProvider` each widget is updated through.
///
/// Fully qualified because the launcher resolves the receiver by class name,
/// and an unqualified name only works when the widget lives in the same
/// package as `MainActivity` — which is a coincidence, not a guarantee.
const _kAndroidPackage = 'org.nehemiah_osc.bible';
const _kDailyVerseProvider = '$_kAndroidPackage.widgets.DailyVerseWidget';
const _kContinueProvider = '$_kAndroidPackage.widgets.ContinueReadingWidget';
const _kStreakProvider = '$_kAndroidPackage.widgets.StreakWidget';

/// How much verse text is sent to the widget at all.
///
/// Sized for the *largest* the daily verse widget can be resized to, not the
/// default: the launcher decides how many lines fit and ellipsizes what does
/// not, and a budget cut to the small size would leave a 4×4 widget half
/// empty with no way to get the rest of the verse back. The cut is still made
/// on a word boundary, which `android:ellipsize` cannot do.
const _kVerseCharBudget = 320;

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
  static Future<void> push(HomeWidgetData data) => _write(
        data.toWidgetEntries(),
        what: 'content',
      );

  /// Writes how the widgets should look, then redraws them.
  ///
  /// Separate from [push] because it is written on a different clock: content
  /// is refreshed on every resume, style only when the user changes it, and a
  /// style change has to take effect on the home screen immediately rather
  /// than at the next resume.
  static Future<void> pushAppearance(HomeWidgetAppearance appearance) => _write(
        appearance.toWidgetEntries(),
        what: 'appearance',
      );

  /// Reads back what [pushAppearance] last wrote.
  ///
  /// The widget preferences are the single copy of this: they outlive the app's
  /// process, the launcher reads them directly, and mirroring them into the
  /// settings database would create a second copy that can disagree. Anything
  /// never written — a fresh install, or a platform with no widgets — falls
  /// back to the defaults in [HomeWidgetAppearance].
  static Future<HomeWidgetAppearance> loadAppearance() async {
    if (!isSupported) return const HomeWidgetAppearance();

    const defaults = HomeWidgetAppearance();
    try {
      var appearance = defaults;
      for (final kind in HomeWidgetKind.values) {
        final fallback = defaults.styleFor(kind);
        final p = kind.prefix;
        appearance = appearance.withStyle(
          kind,
          WidgetStyle(
            // The `??` is not redundant with `defaultValue`: the platform
            // returns null rather than the default on a channel that is not
            // there, and parsing null would quietly hand back `auto` — which
            // is a different widget from the brand card the daily verse
            // defaults to.
            theme: WidgetTheme.parse(
              await HomeWidget.getWidgetData<String>(
                    '${p}_style_theme',
                    defaultValue: fallback.theme.wireName,
                  ) ??
                  fallback.theme.wireName,
            ),
            textScale: WidgetTextScale.parse(
              await HomeWidget.getWidgetData<String>(
                    '${p}_style_scale',
                    defaultValue: fallback.textScale.wireName,
                  ) ??
                  fallback.textScale.wireName,
            ),
            opacity: (await HomeWidget.getWidgetData<int>(
                      '${p}_style_opacity',
                      defaultValue: fallback.opacity,
                    ) ??
                    fallback.opacity)
                .clamp(0, 100),
            showLabel: await _flag('${p}_style_label', fallback.showLabel),
            showDetail: await _flag('${p}_style_detail', fallback.showDetail),
          ),
        );
      }
      return appearance;
    } catch (e) {
      debugPrint('[HomeWidget] appearance read failed: $e');
      return defaults;
    }
  }

  /// Asks the launcher to add [kind] to the home screen.
  ///
  /// Only some launchers implement this, and only from API 26 — hence the
  /// support check rather than a button that silently does nothing.
  static Future<bool> requestPin(HomeWidgetKind kind) async {
    if (!isSupported) return false;
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() != true) return false;
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: _providerFor(kind),
      );
      return true;
    } catch (e) {
      debugPrint('[HomeWidget] pin request failed: $e');
      return false;
    }
  }

  static Future<bool> _flag(String key, bool fallback) async {
    final raw = await HomeWidget.getWidgetData<int>(
      key,
      defaultValue: fallback ? 1 : 0,
    );
    return (raw ?? (fallback ? 1 : 0)) != 0;
  }

  static Future<void> _write(
    Map<String, Object> entries, {
    required String what,
  }) async {
    if (!isSupported) return;
    try {
      for (final entry in entries.entries) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }
      await Future.wait([
        for (final kind in HomeWidgetKind.values)
          HomeWidget.updateWidget(qualifiedAndroidName: _providerFor(kind)),
      ]);
    } catch (e) {
      debugPrint('[HomeWidget] $what update failed: $e');
    }
  }

  static String _providerFor(HomeWidgetKind kind) => switch (kind) {
        HomeWidgetKind.dailyVerse => _kDailyVerseProvider,
        HomeWidgetKind.continueReading => _kContinueProvider,
        HomeWidgetKind.streak => _kStreakProvider,
      };
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
  final verseRefShort = dailyVerse == null
      ? ''
      : shortVerseRef(
          dailyVerse.bookNameEn,
          dailyVerse.chapter,
          dailyVerse.verse,
        );
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
    verseRefShort: verseRefShort,
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
