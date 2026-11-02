import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/features/books/data/models/book_introduction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookIntroduction Model Unit Tests', () {
    final sampleJson = {
      "authorAm": "ሙሴ",
      "authorEn": "Moses",
      "periodAm": "~1450–1410 ዓ.ዓ.",
      "periodEn": "~1450–1410 BC",
      "summaryAm": "ኦሪት ዘፍጥረት የመጽሐፍ ቅዱስ የመጀመሪያው መጽሐፍ ነው።",
      "summaryEn": "The Book of Genesis is the foundational book.",
      "themesAm": ["ፍጥረት", "ቃል ኪዳን"],
      "themesEn": ["Creation", "Covenant"],
      "outline": [
        {
          "titleAm": "የዓለም ፍጥረት",
          "titleEn": "Creation of World",
          "fromChapter": 1,
          "toChapter": 11
        },
        {
          "titleAm": "የአብርሃም ታሪክ",
          "titleEn": "Story of Abraham",
          "fromChapter": 12,
          "toChapter": 25
        }
      ]
    };

    test('BookIntroduction.fromJson correctly parses a complete entry with all Amharic and English fields', () {
      final introAm = BookIntroduction.fromJson(sampleJson, 1, locale: 'am');
      expect(introAm.bookNumber, equals(1));
      expect(introAm.author, equals('ሙሴ'));
      expect(introAm.authorAm, equals('ሙሴ'));
      expect(introAm.authorEn, equals('Moses'));
      expect(introAm.period, equals('~1450–1410 ዓ.ዓ.'));
      expect(introAm.summary, contains('ኦሪት ዘፍጥረት'));
      expect(introAm.themes, contains('ፍጥረት'));
      expect(introAm.outline.length, equals(2));

      final introEn = BookIntroduction.fromJson(sampleJson, 1, locale: 'en');
      expect(introEn.author, equals('Moses'));
      expect(introEn.period, equals('~1450–1410 BC'));
      expect(introEn.summary, contains('foundational book'));
      expect(introEn.themes, contains('Creation'));
    });

    test('BookIntroduction.fromJson falls back to Amharic when English fields are missing', () {
      final jsonNoEn = {
        "authorAm": "ሙሴ",
        "periodAm": "~1450 ዓ.ዓ.",
        "summaryAm": "ኦሪት ዘፍጥረት",
        "themesAm": ["ፍጥረት"],
      };

      final intro = BookIntroduction.fromJson(jsonNoEn, 1, locale: 'en');
      expect(intro.author, equals('ሙሴ'));
      expect(intro.period, equals('~1450 ዓ.ዓ.'));
      expect(intro.summary, equals('ኦሪት ዘፍጥረት'));
      expect(intro.themes, contains('ፍጥረት'));
    });

    test('BookIntroduction.fromJson falls back to empty string when Amharic fields are missing', () {
      final emptyJson = <String, dynamic>{};
      final intro = BookIntroduction.fromJson(emptyJson, 1, locale: 'am');
      expect(intro.author, isEmpty);
      expect(intro.period, isEmpty);
      expect(intro.summary, isEmpty);
    });

    test('BookIntroduction.fromJson handles missing outline array gracefully (empty list, not null)', () {
      final jsonNoOutline = {
        "authorAm": "ሙሴ",
        "summaryAm": "ዘፍጥረት",
      };
      final intro = BookIntroduction.fromJson(jsonNoOutline, 1);
      expect(intro.outline, isA<List<OutlineEntry>>());
      expect(intro.outline, isEmpty);
    });

    test('BookIntroduction.fromJson handles missing themes array gracefully (empty list)', () {
      final jsonNoThemes = {
        "authorAm": "ሙሴ",
        "summaryAm": "ዘፍጥረት",
      };
      final intro = BookIntroduction.fromJson(jsonNoThemes, 1);
      expect(intro.themes, isA<List<String>>());
      expect(intro.themes, isEmpty);
    });

    test('OutlineEntry.fromJson correctly parses titleAm, titleEn, fromChapter, toChapter', () {
      final json = {
        "titleAm": "ፍጥረት",
        "titleEn": "Creation",
        "fromChapter": 1,
        "toChapter": 11,
      };
      final entryAm = OutlineEntry.fromJson(json, locale: 'am');
      expect(entryAm.title, equals('ፍጥረት'));
      expect(entryAm.fromChapter, equals(1));
      expect(entryAm.toChapter, equals(11));

      final entryEn = OutlineEntry.fromJson(json, locale: 'en');
      expect(entryEn.title, equals('Creation'));
    });

    test('OutlineEntry.fromJson falls back titleEn to titleAm when absent', () {
      final jsonNoEn = {
        "titleAm": "ፍጥረት",
        "fromChapter": 1,
        "toChapter": 11,
      };
      final entryEn = OutlineEntry.fromJson(jsonNoEn, locale: 'en');
      expect(entryEn.title, equals('ፍጥረት'));
    });

    test('OutlineEntry enforces toChapter >= fromChapter', () {
      final jsonBadRange = {
        "titleAm": "ፍጥረት",
        "fromChapter": 5,
        "toChapter": 2, // invalid: less than fromChapter
      };
      final entry = OutlineEntry.fromJson(jsonBadRange);
      expect(entry.fromChapter, equals(5));
      expect(entry.toChapter, equals(5)); // adjusted to >= fromChapter
    });

    test('Model is immutable and forLocale creates updated instance', () {
      final amIntro = BookIntroduction.fromJson(sampleJson, 1, locale: 'am');
      expect(amIntro.author, equals('ሙሴ'));

      final enIntro = amIntro.forLocale('en');
      expect(enIntro.author, equals('Moses'));
      expect(amIntro.author, equals('ሙሴ')); // Original un-mutated
    });
  });
}
