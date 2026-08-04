import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/books/data/reading_models.dart';
import 'package:bibleflutter/features/books/providers/reading_progress_providers.dart';
import 'package:bibleflutter/features/home/presentation/pages/streak_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical sizes of real devices, smallest first. The streak page is meant to
/// be read at a glance, so it has to fit each of these without scrolling.
const _devices = <String, Size>{
  // About the tightest screen we support.
  'compact phone': Size(360, 640),
  'Galaxy A56': Size(393, 851),
  'Pixel-class': Size(411, 869),
  'tall phone': Size(412, 915),
};

/// Deliberately unflattering data: a long streak, four-digit totals and a full
/// freeze balance all make their rows as tall as they can get.
ReadingStreakState _streak() => const ReadingStreakState(
      lastQualifiedDate: '2026-07-30',
      currentStreak: 128,
      currentStreakStart: '2026-03-24',
      longestStreak: 365,
      freezeCredits: 2,
    );

Widget _app({AppSettings settings = const AppSettings()}) => ProviderScope(
      overrides: [
        // Layout under test, not the database — the page must not need one.
        readingStreakStateProvider.overrideWith((ref) async => _streak()),
        readingTotalsProvider.overrideWith(
          (ref) async => const ReadingTotals(totalDays: 1284, totalChapters: 9312),
        ),
        readDaysInRangeProvider.overrideWith((ref, range) async => const <String>{}),
      ],
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: Settings(
          notifier: ValueNotifier(settings),
          child: MaterialApp(
            // The page reads its palette off the theme extension, so a bare
            // MaterialApp would fail before laying anything out.
            theme: AppTheme.parchment,
            home: StreakScreen(onReadToday: () {}),
          ),
        ),
      ),
    );

void main() {
  for (final entry in _devices.entries) {
    testWidgets('fits a ${entry.key} with nothing overflowing', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // A RenderFlex overflow throws here; anything non-null means it did not
      // fit.
      expect(tester.takeException(), isNull);

      // Everything the page draws must land inside the viewport.
      final scaffold = tester.renderObject<RenderBox>(find.byType(Scaffold));
      expect(scaffold.size.height, lessThanOrEqualTo(entry.value.height));
      expect(scaffold.size.width, lessThanOrEqualTo(entry.value.width));
    });
  }

  testWidgets('the calendar never scrolls on its own', (tester) async {
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('the page as a whole does not scroll', (tester) async {
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // The calendar grid is the only Scrollable, and it is pinned. Nothing
    // wraps the page in a scroll view any more.
    for (final state in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      expect(state.position.maxScrollExtent, 0,
          reason: 'found a scrollable with content past the fold');
    }
  });

  testWidgets('still fits with Geez numerals, which run wider', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(settings: const AppSettings().copyWith(useGeezNumbers: true)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
