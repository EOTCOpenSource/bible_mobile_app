import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/reading_models.dart';
import 'package:bibleflutter/features/books/providers/reading_progress_providers.dart';
import 'package:bibleflutter/core/widgets/book_cover.dart';
import 'package:bibleflutter/features/home/presentation/pages/home_tab.dart';
import 'package:bibleflutter/features/home/presentation/widgets/continue_reading_section.dart';
import 'package:bibleflutter/features/home/providers/starter_books_provider.dart';
import 'package:bibleflutter/features/topics/data/topic_models.dart';
import 'package:bibleflutter/features/topics/providers/topic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical sizes of real devices, smallest first. Home is meant to be one
/// screen, so it must fit each of these without scrolling.
const _devices = <String, Size>{
  // About the tightest screen we support.
  'compact phone': Size(360, 640),
  'Galaxy A56': Size(393, 851),
  'Pixel-class': Size(411, 869),
  'tall phone': Size(412, 915),
};

const _book = BookIndexEntry(
  id: 'PSA',
  bookNumber: 19,
  bookNameAm: 'መዝሙረ ዳዊት',
  bookNameEn: 'Psalms',
  bookShortNameAm: 'መዝ',
  bookShortNameEn: 'Ps',
  testament: 'OT',
  chapterCount: 150,
);

/// More books than the strip is allowed to show, so the cap is exercised too.
List<ContinueReadingSnapshot> _snapshots(int n) => List.generate(
      n,
      (i) => ContinueReadingSnapshot(
        entry: _book,
        position: ReadingPosition(
            bookId: 'PSA', chapter: 3 + i, verse: 2, updatedAtMs: 1000 - i),
        chaptersReadInBook: 40 + i,
        totalChapters: 150,
      ),
    );

List<TopicEntry> _topics() => List.generate(
      15,
      (i) => TopicEntry(
        id: 'topic$i',
        labelAm: 'አርእስት $i',
        labelEn: 'Topic $i',
        icon: '🙏',
        image: null,
        keywords: const ['ጸሎት'],
      ),
    );

/// Stand-ins for the books a fresh install would be offered.
List<BookIndexEntry> _starters(int n) => List.generate(
      n,
      (i) => BookIndexEntry(
        id: ['JHN', 'PSA', 'GEN'][i % 3],
        bookNumber: 40 + i,
        bookNameAm: 'ወንጌለ ዮሐንስ',
        bookNameEn: 'John',
        bookShortNameAm: 'ዮሐ',
        bookShortNameEn: 'Jn',
        testament: 'NT',
        chapterCount: 21,
      ),
    );

Widget _app({
  AppSettings settings = const AppSettings(),
  double textScale = 1.0,
  int books = 0,
  int starters = 3,
}) =>
    ProviderScope(
      overrides: [
        // Layout under test, not the database.
        readingStreakStateProvider.overrideWith(
          (ref) async => const ReadingStreakState(currentStreak: 128),
        ),
        continueReadingSnapshotsProvider.overrideWith((ref) async => _snapshots(books)),
        topicsProvider.overrideWith((ref) async => _topics()),
        starterBooksProvider.overrideWith((ref) async => _starters(starters)),
      ],
      child: BibleRepositoryProvider(
        // No edition is installed in a test, so the daily verse resolves to its
        // "unavailable" state — which is exactly a case the card must still fit.
        repository: BibleRepository(),
        child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: Settings(
          notifier: ValueNotifier(settings),
          child: MaterialApp(
            theme: AppTheme.parchment,
            // Home never gets the whole screen in the real app: a status bar
            // and gesture inset come off the top and bottom, and the bottom
            // nav takes 64 more. Testing without those passed a layout that
            // overflowed on a real phone.
            home: MediaQuery(
              data: MediaQueryData(
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                // Widget tests do not load the app's Ethiopic fonts and fall
                // back to metrics that are shorter than the real thing, so a
                // layout can pass here and still overflow on a phone. Scaling
                // text up is the closest approximation available offline — and
                // it doubles as the accessibility case.
                textScaler: TextScaler.linear(textScale),
              ),
              child: Scaffold(
                body: HomeTab(onSwitchToBooks: () {}),
                bottomNavigationBar: const SizedBox(height: 64),
              ),
            ),
          ),
        ),
        ),
      ),
    );

void main() {
  for (final entry in _devices.entries) {
    testWidgets('home fits a ${entry.key} with nothing overflowing',
        (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pump();

      // A RenderFlex overflow throws here.
      expect(tester.takeException(), isNull);

      final scaffold = tester.renderObject<RenderBox>(find.byType(Scaffold));
      expect(scaffold.size.height, lessThanOrEqualTo(entry.value.height));
    });
  }

  testWidgets('home itself never scrolls vertically on a normal phone',
      (tester) async {
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pump();

    // The only scrollables are the horizontal strips; nothing scrolls the page.
    for (final state
        in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      expect(state.position.axis, Axis.horizontal,
          reason: 'home gained a vertical scroll view');
    }
  });

  group('viewports too short for the one-screen layout', () {
    // Split-screen, a small phone in landscape, and the transient short
    // viewport a real device reports while insets settle during startup.
    for (final height in [580.0, 560.0, 480.0, 400.0, 320.0]) {
      testWidgets('scrolls instead of clipping at ${height.toInt()}dp',
          (tester) async {
        tester.view.physicalSize = Size(393, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app());
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'the page clipped instead of scrolling');
      });
    }

    testWidgets('the fallback is a real vertical scroll view', (tester) async {
      tester.view.physicalSize = const Size(393, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pump();

      final vertical = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .where((s) => s.position.axis == Axis.vertical);

      expect(vertical, isNotEmpty, reason: 'nothing lets the user reach the '
          'bottom of the page');
      expect(vertical.first.position.maxScrollExtent, greaterThan(0));
    });
  });

  group('taller text than the test font reports', () {
    for (final scale in [1.1, 1.2, 1.3]) {
      testWidgets('no clipping at ${scale}x text on a Galaxy A56',
          (tester) async {
        tester.view.physicalSize = const Size(393, 851);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(textScale: scale));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the continue-reading strip', () {
    for (final books in [1, 3, 12]) {
      testWidgets('$books book(s) on shelf still fits a Galaxy A56',
          (tester) async {
        tester.view.physicalSize = const Size(393, 851);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(books: books));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows at most the ten most recent books', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 25));
      await tester.pumpAndSettle();

      // The strip is lazy, so count what it was given rather than what is
      // painted: scroll to the end and no eleventh tile appears.
      final strip = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(ListView),
      );
      final list = tester.widget<ListView>(strip);
      expect(list.semanticChildCount, ContinueReadingSection.maxBooks);
    });

    testWidgets('has no page indicator any more', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 5));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ContinueReadingSection),
          matching: find.byType(PageView),
        ),
        findsNothing,
        reason: 'the strip scrolls; it does not page',
      );
    });

    testWidgets('the last visible cover has room for its shadow',
        (tester) async {
      const width = 393.0;
      tester.view.physicalSize = const Size(width, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 6));
      await tester.pumpAndSettle();

      // A cover throws its shadow down and to the right past its own box. The
      // third one used to end flush against the viewport and get sliced.
      final covers = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(BookCover),
      );

      final rightmostOnScreen = covers
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)))
          .where((r) => r.right <= width)
          .reduce((a, b) => a.right > b.right ? a : b);

      expect(width - rightmostOnScreen.right, greaterThanOrEqualTo(12),
          reason: 'no clearance left for the drop shadow');
    });

    testWidgets('the strip runs edge to edge so it can inset itself',
        (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 6));
      await tester.pumpAndSettle();

      final strip = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(ListView),
      );
      // Full width: the padding lives on the list, not around it, which is
      // what gives the shadow somewhere to land.
      expect(tester.getRect(strip).width, 393);
    });

    testWidgets('several covers are on screen at once', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 5));
      await tester.pumpAndSettle();

      // The old layout showed exactly one book at a time.
      final covers = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(BookCover),
      );
      expect(covers.evaluate().length, greaterThanOrEqualTo(3));
    });
  });

  group('a reader with no history', () {
    testWidgets('is offered books to start rather than a dead end',
        (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 0, starters: 3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Real covers, not a single signpost card.
      final covers = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(BookCover),
      );
      expect(covers.evaluate().length, greaterThanOrEqualTo(kMinStarterBooks));
    });

    testWidgets('never shows fewer than the minimum', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 0, starters: kMinStarterBooks));
      await tester.pumpAndSettle();

      final covers = find.descendant(
        of: find.byType(ContinueReadingSection),
        matching: find.byType(BookCover),
      );
      expect(covers.evaluate().length, kMinStarterBooks);
    });

    testWidgets('the heading says start, not continue', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 0));
      await tester.pumpAndSettle();

      const am = AmStrings();
      expect(find.text(am.startReadingTitle), findsOneWidget);
      expect(find.text(am.continueReadingTitle), findsNothing);
    });

    testWidgets('with an edition installed but no suggestions, the signpost '
        'still shows', (tester) async {
      tester.view.physicalSize = const Size(393, 851);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 0, starters: 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      const am = AmStrings();
      // Falls back to the "go to the books tab" card rather than a blank row.
      expect(find.text(am.streakReadTodayHint), findsOneWidget);
    });

    testWidgets('the starter shelf fits a compact phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(books: 0, starters: 3));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('still fits with Geez numerals, which run wider', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(settings: const AppSettings().copyWith(useGeezNumbers: true)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
