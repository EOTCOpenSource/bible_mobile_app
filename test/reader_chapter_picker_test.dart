import 'package:bibleflutter/core/l10n/en_strings.dart';
import 'package:bibleflutter/features/books/data/models/book.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/models/edition.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/chapter_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('edition short label', () {
    Edition edition({
      String id = 'am-2000',
      String abbrev = '',
      String languageName = 'አማርኛ',
      String language = 'am',
      int? year,
      String? era,
    }) =>
        Edition(
          id: id,
          title: 'መጽሐፍ ቅዱስ፣ ሰማንያ አሐዱ በአማርኛ',
          titleEn: 'Amharic Bible, 81 books',
          abbrev: abbrev,
          language: language,
          languageName: languageName,
          script: 'Ethi',
          direction: 'ltr',
          canon: 'eotc-81',
          books: 89,
          chapters: 1300,
          verses: 40000,
          file: '$id.db',
          year: year,
          era: era,
        );

    test('is language and year, never the catalog abbreviation', () {
      // The real am-2000 row carries a whole title in `abbrev`, which is what
      // made the chip too wide to read.
      final e = edition(
        abbrev: 'መጽሐፍ ቅዱስ አማርኛ የ2000 ዓ.ም ዕትም',
        year: 2000,
        era: 'EC',
      );
      expect(e.shortLabel, 'አማርኛ 2000');
      expect(e.shortLabel, isNot(contains('መጽሐፍ')));
    });

    test('drops the era, which the chooser row still shows', () {
      final e = edition(year: 2000, era: 'EC');
      expect(e.shortLabel, 'አማርኛ 2000');
      expect(e.yearLabel, '2000 EC');
    });

    test('an edition with no year is just its language', () {
      final e = edition(
        id: 'om-kitaaba',
        languageName: 'Afaan Oromoo',
        language: 'om',
      );
      expect(e.shortLabel, 'Afaan Oromoo');
    });

    test('falls back to the language tag when unnamed', () {
      final e = edition(languageName: '', year: 1611);
      expect(e.shortLabel, 'AM 1611');
    });
  });

  group('chapter picker', () {
    const entry = BookIndexEntry(
      id: 'GEN',
      bookNumber: 1,
      bookNameAm: 'ኦሪት ዘፍጥረት',
      bookNameEn: 'Genesis',
      bookShortNameAm: 'ዘፍ',
      bookShortNameEn: 'Gen',
      testament: 'OT',
    );

    List<Chapter> chapters(int n) => [
          for (var i = 1; i <= n; i++)
            Chapter(chapterNumber: i, sections: const []),
        ];

    Widget wrap({
      required List<Chapter> list,
      required ValueChanged<int> onSelect,
      int currentIndex = 0,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: ReaderChapterPicker(
              entry: entry,
              chapters: list,
              currentIndex: currentIndex,
              useGeez: false,
              isAmharic: false,
              s: EnStrings(),
              surfaceColor: Colors.white,
              textColor: Colors.black,
              mutedColor: Colors.grey,
              accentColor: Colors.brown,
              titleFontFamily: 'Roboto',
              onSelect: onSelect,
            ),
          ),
        );

    testWidgets('reports the index of the chapter tapped', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        wrap(list: chapters(10), onSelect: picked.add),
      );

      await tester.tap(find.text('4'));
      await tester.pump();

      // Index 3, not chapter number 4 — the reader pages by index.
      expect(picked, [3]);
    });

    testWidgets('numbers come from the chapter, not the position',
        (tester) async {
      // A book whose edition starts at chapter 3 must not offer a "1".
      final odd = [
        const Chapter(chapterNumber: 3, sections: []),
        const Chapter(chapterNumber: 4, sections: []),
      ];
      final picked = <int>[];
      await tester.pumpWidget(wrap(list: odd, onSelect: picked.add));

      expect(find.text('1'), findsNothing);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('4'));
      await tester.pump();
      expect(picked, [1]);
    });

    testWidgets('shows the book name and chapter count', (tester) async {
      await tester.pumpWidget(wrap(list: chapters(50), onSelect: (_) {}));

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('50 ${EnStrings().chapterAbbr}'), findsOneWidget);
    });
  });
}
