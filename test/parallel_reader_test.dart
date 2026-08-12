import 'package:bibleflutter/core/annotations/annotation_models.dart';
import 'package:bibleflutter/core/l10n/en_strings.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/books/data/models/book.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/parallel_chapter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The parallel reader aligns two editions by verse number. These cover the
/// cases where the two disagree, which is where index-based pairing would put
/// the wrong two verses next to each other.
void main() {
  const entry = BookIndexEntry(
    id: 'GEN',
    bookNumber: 1,
    bookNameAm: 'ኦሪት ዘፍጥረት',
    bookNameEn: 'Genesis',
    bookShortNameAm: 'ዘፍ',
    bookShortNameEn: 'Gen',
    testament: 'OT',
  );

  Verse verse(int n, String text) => Verse(
        ord: n - 1,
        verseNumber: n,
        label: '$n',
        text: text,
      );

  Chapter chapter(List<Verse> verses, {String title = ''}) => Chapter(
        chapterNumber: 1,
        sections: [Section(title: title, verses: verses)],
      );

  Widget wrap(WidgetTester tester, Widget child, {Size size = const Size(900, 1200)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return Settings(
      notifier: ValueNotifier(const AppSettings()),
      child: MaterialApp(
        theme: AppTheme.parchment,
        home: Scaffold(body: child),
      ),
    );
  }

  ParallelChapterPage page({
    required Chapter primary,
    Chapter? secondary,
    bool bookMissing = false,
  }) =>
      ParallelChapterPage(
        entry: entry,
        chapter: primary,
        secondaryChapter: secondary,
        secondaryBookMissing: bookMissing,
        primaryLabel: 'AM',
        secondaryLabel: 'KJV',
        isDark: false,
        fontSize: 17,
        fontFamily: 'Roboto',
        titleFontFamily: 'Roboto',
        textColor: Colors.black,
        mutedColor: Colors.grey,
        accentColor: Colors.brown,
        useGeez: false,
        isAmharic: false,
        s: EnStrings(),
        isSelectedFn: (_, _, _) => false,
        onVerseTap: (_) {},
        verseKeyFn: (c, s, v) => '$c:$s:$v',
        annotations: ChapterAnnotations.empty,
      );

  testWidgets('renders both editions side by side on a wide screen',
      (tester) async {
    await tester.pumpWidget(wrap(tester, page(
      primary: chapter([verse(1, 'primary one'), verse(2, 'primary two')]),
      secondary: chapter([verse(1, 'secondary one'), verse(2, 'secondary two')]),
    )));

    expect(find.text('AM'), findsOneWidget);
    expect(find.text('KJV'), findsOneWidget);

    final primary =
        tester.getTopLeft(find.textContaining('primary one', findRichText: true));
    final secondary = tester
        .getTopLeft(find.textContaining('secondary one', findRichText: true));
    expect(secondary.dx, greaterThan(primary.dx));
    expect(secondary.dy, primary.dy);
  });

  testWidgets('a verse only the primary has still renders', (tester) async {
    // The second edition folds verse 2 into verse 1, which is the ordinary
    // versification disagreement between editions.
    await tester.pumpWidget(wrap(tester, page(
      primary: chapter([
        verse(1, 'primary one'),
        verse(2, 'primary two'),
        verse(3, 'primary three'),
      ]),
      secondary: chapter([verse(1, 'secondary one'), verse(3, 'secondary three')]),
    )));

    expect(find.textContaining('primary two', findRichText: true), findsOneWidget);
    // Verse 3 must still sit opposite verse 3, not slide up into the gap.
    expect(find.textContaining('secondary three', findRichText: true), findsOneWidget);
    expect(find.textContaining('secondary two', findRichText: true), findsNothing);
  });

  testWidgets('a verse only the parallel edition has is not dropped',
      (tester) async {
    await tester.pumpWidget(wrap(tester, page(
      primary: chapter([verse(1, 'primary one'), verse(3, 'primary three')]),
      secondary: chapter([
        verse(1, 'secondary one'),
        verse(2, 'secondary two'),
        verse(3, 'secondary three'),
      ]),
    )));

    expect(find.textContaining('secondary two', findRichText: true), findsOneWidget);
    expect(find.textContaining('primary three', findRichText: true), findsOneWidget);
  });

  testWidgets('stacks the pair on a narrow screen', (tester) async {
    await tester.pumpWidget(wrap(
      tester,
      page(
        primary: chapter([verse(1, 'primary one')]),
        secondary: chapter([verse(1, 'secondary one')]),
      ),
      size: const Size(400, 900),
    ));

    expect(find.textContaining('primary one', findRichText: true), findsOneWidget);
    expect(find.textContaining('secondary one', findRichText: true), findsOneWidget);

    final primary = tester.getTopLeft(
      find.textContaining('primary one', findRichText: true),
    );
    final secondary = tester.getTopLeft(
      find.textContaining('secondary one', findRichText: true),
    );
    // Stacked, not columned: the second translation sits below its verse.
    expect(secondary.dy, greaterThan(primary.dy));
  });

  testWidgets('says so when the parallel canon has no such book',
      (tester) async {
    await tester.pumpWidget(wrap(tester, page(
      primary: chapter([verse(1, 'primary one')]),
      secondary: null,
      bookMissing: true,
    )));

    expect(
      find.text(EnStrings().parallelBookMissing('KJV')),
      findsOneWidget,
    );
    // One column, not an empty second one.
    expect(find.textContaining('primary one', findRichText: true), findsOneWidget);
    expect(find.text('KJV'), findsNothing);
  });
}
