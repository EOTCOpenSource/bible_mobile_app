import 'package:bibleflutter/core/home_widget/home_widget_data.dart';
import 'package:bibleflutter/core/home_widget/widget_appearance.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/me/presentation/pages/widgets_settings_page.dart';
import 'package:bibleflutter/features/me/presentation/widgets/home_widget_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _s = AmStrings();

/// A payload with every field populated and a verse long enough to run past
/// the preview's box — the case where a preview is most likely to overflow.
final _data = HomeWidgetData(
  verseText: List.filled(40, 'ቃል').join(' '),
  verseRef: 'ትንቢተ ኤርምያስ 29:11',
  verseRefShort: 'JER 29:11',
  verseDeepLink: 'eotcbible://openinapp/jer29_11',
  continueBook: 'መጽሐፈ ነገሥት ቀዳማዊ',
  continueRef: 'ምዕ. 8',
  continueProgress: 36,
  continueDeepLink: 'eotcbible://openinapp/1kgs8_22',
  streakCount: 128,
  streakCountLabel: '128',
  streakEmoji: '🔥',
  streakSuffix: 'ቀናት',
  streakDeepLink: 'eotcbible://openinapp/streak',
);

Widget _preview({
  required HomeWidgetKind kind,
  WidgetStyle style = const WidgetStyle(),
  HomeWidgetData? data,
  double width = 340,
}) =>
    MaterialApp(
      theme: AppTheme.parchment,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: HomeWidgetPreview(
              kind: kind,
              style: style,
              data: data ?? _data,
              s: _s,
              systemDark: false,
            ),
          ),
        ),
      ),
    );

Widget _page({AppSettings settings = const AppSettings()}) => ProviderScope(
      // Deliberately no overrides. The page's payload load reaches for the
      // repository and the streak, and both are expected to fail in a test
      // binding — the page has to survive that and draw its empty states,
      // which is exactly what a brand new install sees.
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: Settings(
          notifier: ValueNotifier(settings),
          child: MaterialApp(
            theme: AppTheme.parchment,
            home: const WidgetsSettingsPage(),
          ),
        ),
      ),
    );

void main() {
  group('HomeWidgetPreview', () {
    // Every combination the settings page can produce. The preview is the only
    // place a bad combination is visible before it reaches someone's home
    // screen, so it has to survive all of them.
    for (final kind in HomeWidgetKind.values) {
      for (final theme in WidgetTheme.values) {
        for (final scale in WidgetTextScale.values) {
          testWidgets(
            'draws ${kind.name} in ${theme.wireName} at ${scale.wireName} '
            'without overflowing',
            (tester) async {
              await tester.pumpWidget(
                _preview(
                  kind: kind,
                  style: WidgetStyle(theme: theme, textScale: scale),
                ),
              );
              await tester.pump();

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('survives the narrowest screen we support', (tester) async {
      for (final kind in HomeWidgetKind.values) {
        await tester.pumpWidget(
          _preview(
            kind: kind,
            style: const WidgetStyle(textScale: WidgetTextScale.large),
            // 360dp screen less the page's own 16dp margins and the preview
            // stage's 18dp padding.
            width: 292,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: kind.name);
      }
    });

    // The card can go all the way to invisible. The text on it must not, or
    // the setting would just be a way to blank the widget.
    testWidgets('a fully transparent card still draws its text',
        (tester) async {
      for (final kind in HomeWidgetKind.values) {
        await tester.pumpWidget(
          _preview(kind: kind, style: const WidgetStyle(opacity: 0)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: kind.name);
      }

      expect(find.text('ትንቢተ ኤርምያስ 29:11'), findsNothing);
      await tester.pumpWidget(
        _preview(
          kind: HomeWidgetKind.dailyVerse,
          style: const WidgetStyle(opacity: 0),
        ),
      );
      await tester.pump();
      expect(find.text('ትንቢተ ኤርምያስ 29:11'), findsOneWidget);
    });

    // A short verse has slack in its box; a long one has none. Both have to
    // land inside the card, which is what centring can quietly break.
    testWidgets('a short verse sits in the card without overflowing it',
        (tester) async {
      await tester.pumpWidget(
        _preview(
          kind: HomeWidgetKind.dailyVerse,
          data: _short(),
          style: const WidgetStyle(textScale: WidgetTextScale.large),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('ጌታ እረኛዬ ነው።'), findsOneWidget);
    });

    testWidgets('the label toggle hides the daily verse tag', (tester) async {
      await tester.pumpWidget(_preview(kind: HomeWidgetKind.dailyVerse));
      await tester.pump();
      expect(find.text(_s.dailyVerseTag), findsOneWidget);
      expect(find.text('JER 29:11'), findsOneWidget);

      await tester.pumpWidget(
        _preview(
          kind: HomeWidgetKind.dailyVerse,
          style: const WidgetStyle(showLabel: false),
        ),
      );
      await tester.pump();
      // The corner reference lives in the tag row, so it goes with it.
      expect(find.text(_s.dailyVerseTag), findsNothing);
      expect(find.text('JER 29:11'), findsNothing);
    });

    testWidgets('the detail toggle hides the reference line', (tester) async {
      await tester.pumpWidget(_preview(kind: HomeWidgetKind.dailyVerse));
      await tester.pump();
      expect(find.text('ትንቢተ ኤርምያስ 29:11'), findsOneWidget);

      await tester.pumpWidget(
        _preview(
          kind: HomeWidgetKind.dailyVerse,
          style: const WidgetStyle(showDetail: false),
        ),
      );
      await tester.pump();
      expect(find.text('ትንቢተ ኤርምያስ 29:11'), findsNothing);
    });

    testWidgets('the streak toggles hide the emoji and the suffix',
        (tester) async {
      await tester.pumpWidget(_preview(kind: HomeWidgetKind.streak));
      await tester.pump();
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('ቀናት'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);

      await tester.pumpWidget(
        _preview(
          kind: HomeWidgetKind.streak,
          style: const WidgetStyle(showLabel: false, showDetail: false),
        ),
      );
      await tester.pump();
      expect(find.text('🔥'), findsNothing);
      expect(find.text('ቀናት'), findsNothing);
      // The count is never optional — it is the reason the widget exists.
      expect(find.text('128'), findsOneWidget);
    });

    testWidgets('an empty payload previews the prompt, not a blank card',
        (tester) async {
      await tester.pumpWidget(
        _preview(kind: HomeWidgetKind.dailyVerse, data: _empty()),
      );
      await tester.pump();
      expect(find.text(_s.widgetEmptyVerse), findsOneWidget);

      await tester.pumpWidget(
        _preview(kind: HomeWidgetKind.continueReading, data: _empty()),
      );
      await tester.pump();
      expect(find.text(_s.widgetEmptyContinue), findsOneWidget);
    });
  });

  group('WidgetsSettingsPage', () {
    testWidgets('lays out on the tightest screen we support', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The chooser strip names all three widgets, which is where "customise
      // all of them, not just the streak" is visible on the page itself.
      expect(find.text(_s.widgetNameDailyVerse), findsWidgets);
      expect(find.text(_s.widgetNameContinue), findsWidgets);
      expect(find.text(_s.widgetNameStreak), findsWidgets);
    });

    // Tall enough that the whole page is built at once — the controls below
    // the fold are what these assertions are about, not where they land.
    testWidgets('the controls follow the widget chosen in the strip',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      // Opens on the daily verse, so the toggles are the daily verse's.
      expect(find.text(_s.widgetToggleVerseTag), findsOneWidget);
      expect(find.text(_s.widgetToggleVerseRef), findsOneWidget);
      expect(find.text(_s.streakEmojiSectionChoose), findsNothing);

      await tester.tap(find.text(_s.widgetNameStreak).first);
      await tester.pumpAndSettle();

      expect(find.text(_s.widgetToggleStreakDays), findsOneWidget);
      expect(find.text(_s.widgetToggleVerseTag), findsNothing);
      // The emoji picker belongs to the streak widget alone.
      expect(find.text(_s.streakEmojiSectionChoose), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changing the text size redraws the preview', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      await tester.tap(find.text(_s.widgetTextLarge));
      await tester.pumpAndSettle();

      expect(
        tester.widget<HomeWidgetPreview>(find.byType(HomeWidgetPreview)).style
            .textScale,
        WidgetTextScale.large,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// A verse far shorter than its box, so the card has slack to centre it in.
HomeWidgetData _short() => HomeWidgetData(
      verseText: 'ጌታ እረኛዬ ነው።',
      verseRef: 'መዝሙረ ዳዊት 23:1',
      verseRefShort: 'PSA 23:1',
      verseDeepLink: _data.verseDeepLink,
      continueBook: _data.continueBook,
      continueRef: _data.continueRef,
      continueProgress: _data.continueProgress,
      continueDeepLink: _data.continueDeepLink,
      streakCount: _data.streakCount,
      streakCountLabel: _data.streakCountLabel,
      streakEmoji: _data.streakEmoji,
      streakSuffix: _data.streakSuffix,
      streakDeepLink: _data.streakDeepLink,
    );

/// The state before the app has ever run: no verse, no reading history.
HomeWidgetData _empty() => const HomeWidgetData(
      verseText: '',
      verseRef: '',
      verseRefShort: '',
      verseDeepLink: '',
      continueBook: '',
      continueRef: '',
      continueProgress: 0,
      continueDeepLink: '',
      streakCount: 0,
      streakCountLabel: '0',
      streakEmoji: '🔥',
      streakSuffix: 'ቀናት',
      streakDeepLink: 'eotcbible://openinapp/streak',
    );
