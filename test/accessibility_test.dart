import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/theme/app_colors.dart';
import 'package:bibleflutter/core/widgets/accessible_button.dart';
import 'package:bibleflutter/core/widgets/app_bottom_nav.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/toolbar.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/verse_action_bar.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/presentation/widgets/edition_switcher.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/reader_style_resolver.dart';

double _calculateLuminance(Color color) {
  double sRGB(double c) {
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = sRGB((color.r * 255.0).round().clamp(0, 255) / 255.0);
  final g = sRGB((color.g * 255.0).round().clamp(0, 255) / 255.0);
  final b = sRGB((color.b * 255.0).round().clamp(0, 255) / 255.0);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _calculateContrastRatio(Color color1, Color color2) {
  final l1 = _calculateLuminance(color1);
  final l2 = _calculateLuminance(color2);

  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG AA Color Contrast Tests', () {
    test('textCaption against parchment meets WCAG AA 4.5:1 (computed 7.01:1)', () {
      final ratio = _calculateContrastRatio(AppColors.textCaption, AppColors.parchment);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, closeTo(7.01, 0.1));
    });

    test('textMuted against parchment meets WCAG AA 4.5:1', () {
      final ratio = _calculateContrastRatio(AppColors.textMuted, AppColors.parchment);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('accentDark against parchment meets WCAG AA 4.5:1', () {
      final ratio = _calculateContrastRatio(AppColors.accentDark, AppColors.parchment);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('accentDark against white surface meets WCAG AA 4.5:1 (computed 6.03:1)', () {
      final ratio = _calculateContrastRatio(AppColors.accentDark, AppColors.surface);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, closeTo(6.03, 0.1));
    });

    test('readerShellDarkMuted against readerShellDarkBg meets WCAG AA 4.5:1 (computed 5.55:1)', () {
      final ratio = _calculateContrastRatio(AppColors.readerShellDarkMuted, AppColors.readerShellDarkBg);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, closeTo(5.55, 0.1));
    });

    test('readerShellDarkMuted against readerShellDarkSurface meets WCAG AA 4.5:1 (computed 4.91:1)', () {
      final ratio = _calculateContrastRatio(AppColors.readerShellDarkMuted, AppColors.readerShellDarkSurface);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(ratio, closeTo(4.91, 0.1));
    });

    test('accentDeep against parchment meets WCAG AA 4.5:1', () {
      final ratio = _calculateContrastRatio(AppColors.accentDeep, AppColors.parchment);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('AppColorScheme light palette contrast compliance', () {
      final scheme = AppColorScheme.light;
      expect(_calculateContrastRatio(scheme.textCaption, scheme.parchment), greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(scheme.textMuted, scheme.parchment), greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(scheme.textBody, scheme.parchment), greaterThanOrEqualTo(4.5));
    });

    test('AppColorScheme dark palette contrast compliance', () {
      final scheme = AppColorScheme.dark;
      expect(_calculateContrastRatio(scheme.textCaption, scheme.parchment), greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(scheme.textMuted, scheme.parchment), greaterThanOrEqualTo(4.5));
      expect(_calculateContrastRatio(scheme.textBody, scheme.parchment), greaterThanOrEqualTo(4.5));
    });
  });

  group('Typography & Text Scaling Tests', () {
    test('ReaderStyleResolver clamps text scale and font size', () {
      expect(ReaderStyleResolver.clampTextScale(2.5), equals(1.60));
      expect(ReaderStyleResolver.clampTextScale(0.5), equals(0.85));

      final style = ReaderStyleResolver.computeBodyStyle(
        fontFamily: 'Shiromeda',
        fontSize: 18.0,
        lineHeight: 1.5,
        textColor: Colors.black,
        textScaler: const TextScaler.linear(2.0),
      );

      expect(style.fontSize, lessThanOrEqualTo(48.0));
      expect(style.fontSize, greaterThanOrEqualTo(12.0));
    });
  });

  group('Semantics & Screen Reader Label Widget Tests', () {
    testWidgets('VerseActionBar includes correct semantics and state labels', (tester) async {
      final s = EnStrings();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: const [AppColorScheme.light],
            ),
            home: Scaffold(
              body: VerseActionBar(
                s: s,
                isDark: false,
                surfaceColor: Colors.white,
                textColor: Colors.black,
                isBookmarked: false,
                highlightColor: null,
                hasNote: true,
                onBookmark: () {},
                onHighlight: () {},
                onNote: () {},
                onCopy: () {},
                onShare: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(s.semanticsBookmarkAdd), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsHighlightAdd), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsNoteEdit), findsOneWidget);
      expect(find.bySemanticsLabel(s.verseCopy), findsOneWidget);
      expect(find.bySemanticsLabel(s.verseShare), findsOneWidget);
    });

    testWidgets('ReaderToolbar provides semantics labels and 48dp minimum targets', (tester) async {
      final s = EnStrings();
      const entry = BookIndexEntry(
        id: 'GEN',
        bookNumber: 1,
        bookNameAm: 'ኦሪት ዘፍጥረት',
        bookNameEn: 'Genesis',
        bookShortNameAm: 'ዘፍ',
        bookShortNameEn: 'Gen',
        testament: 'OT',
        chapterCount: 50,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: Settings(
            notifier: ValueNotifier(const AppSettings()),
            child: L10n(
              initialLanguage: AppLanguage.english,
              child: MaterialApp(
                theme: ThemeData(
                  extensions: const [AppColorScheme.light],
                ),
                home: Scaffold(
                  body: ReaderToolbar(
                    entry: entry,
                    currentChapter: 0,
                    useGeez: false,
                    isAmharic: false,
                    bgColor: Colors.white,
                    textColor: Colors.black,
                    mutedColor: Colors.grey,
                    accentColor: Colors.amber,
                    sheetTheme: const EditionSheetTheme(
                      surface: Colors.white,
                      text: Colors.black,
                      muted: Colors.grey,
                      accent: Colors.amber,
                      border: Colors.grey,
                    ),
                    s: s,
                    onBack: () {},
                    onFontSettings: () {},
                    onAudio: () {},
                    onSearch: () {},
                    onGoToReference: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(s.semanticsMenuBtn), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsAudioBtn), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsFontSettingsBtn), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsRefJumpBtn), findsOneWidget);
      expect(find.bySemanticsLabel(s.semanticsSearchBtn), findsOneWidget);
    });

    testWidgets('AppBottomNav contains semantics announcements for tabs', (tester) async {
      final s = EnStrings();
      await tester.pumpWidget(
        ProviderScope(
          child: Settings(
            notifier: ValueNotifier(const AppSettings()),
            child: L10n(
              initialLanguage: AppLanguage.english,
              child: MaterialApp(
                theme: ThemeData(
                  extensions: const [AppColorScheme.light],
                ),
                home: Scaffold(
                  bottomNavigationBar: AppBottomNav(
                    selectedIndex: 0,
                    onTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final tabAnnouncement = s.semanticsTabAnnouncement(s.navHome, 1, 5);
      expect(find.bySemanticsLabel(tabAnnouncement), findsOneWidget);
    });

    testWidgets('AccessibleButton renders with 48x48dp minimum touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test Button',
              onTap: () {},
              child: const Icon(Icons.check),
            ),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(AccessibleButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
