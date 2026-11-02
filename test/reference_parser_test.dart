import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/reference_parser.dart';

void main() {
  final index = [
    const BookIndexEntry(
      id: 'JHN',
      bookNumber: 43,
      bookNameAm: 'የዮሐንስ ወንጌል',
      bookNameEn: 'John',
      bookShortNameAm: 'ዮሐንስ',
      bookShortNameEn: 'John',
      testament: 'new',
      chapterCount: 21,
    ),
    const BookIndexEntry(
      id: '1SA',
      bookNumber: 9,
      bookNameAm: 'መጽሐፈ ሳሙኤል ቀዳማዊ',
      bookNameEn: '1 Samuel',
      bookShortNameAm: '1 ሳሙኤል',
      bookShortNameEn: '1 Sam',
      testament: 'old',
      chapterCount: 31,
    ),
    const BookIndexEntry(
      id: 'ENO',
      bookNumber: 82,
      bookNameAm: 'መጽሐፈ ሄኖክ',
      bookNameEn: 'Enoch',
      bookShortNameAm: 'ሄኖክ',
      bookShortNameEn: 'Enoch',
      testament: 'deuterocanonical',
    ),
    const BookIndexEntry(
      id: '1MA',
      bookNumber: 83,
      bookNameAm: 'መጽሐፈ መቃብያን ቀዳማዊ',
      bookNameEn: '1 Maccabees',
      bookShortNameAm: '1 መቃብያን',
      bookShortNameEn: '1 Mecca',
      testament: 'deuterocanonical',
    ),
    const BookIndexEntry(
      id: 'MRK',
      bookNumber: 41,
      bookNameAm: 'የማርቆስ ወንጌል',
      bookNameEn: 'Mark',
      bookShortNameAm: 'ማርቆስ',
      bookShortNameEn: 'Mark',
      testament: 'new',
      chapterCount: 16,
    ),
    const BookIndexEntry(
      id: 'MAT',
      bookNumber: 40,
      bookNameAm: 'የማቴዎስ ወንጌል',
      bookNameEn: 'Matthew',
      bookShortNameAm: 'ማቴዎስ',
      bookShortNameEn: 'Matt',
      testament: 'new',
      chapterCount: 28,
    ),
  ];

  group('parseReference', () {
    test('Empty string', () {
      expect(parseReference('', index), isEmpty);
    });

    test('Unknown book', () {
      expect(parseReference('unknown 1:1', index), isEmpty);
    });

    test('Out-of-range chapter', () {
      expect(parseReference('John 22', index), isEmpty); // JHN has 21 chapters
    });

    test('Ambiguous abbreviation', () {
      final res = parseReference('ማ 1', index);
      expect(res.length, greaterThanOrEqualTo(2)); // Both Mark and Matthew start with 'ማ'
      expect(res.any((r) => r.book.id == 'MRK'), isTrue);
      expect(res.any((r) => r.book.id == 'MAT'), isTrue);
    });

    test('Valid inputs', () {
      final tests = {
        'ዮሐ 3:16': ('JHN', 3, 16),
        'ዮሐንስ 3፥16': ('JHN', 3, 16),
        'john 3:16': ('JHN', 3, 16),
        'jn3:16': ('JHN', 3, 16), // 'jn' doesn't exactly match 'John' or 'ዮሐንስ', wait, does it? 
        '1ሳሙ 17': ('1SA', 17, null),
        '1 sam 17 4': ('1SA', 17, 4),
        '፹፩ 3': null, // No book ፹፩ in index
      };

      for (final entry in tests.entries) {
        final res = parseReference(entry.key, index, useGeezNumbers: true);
        if (entry.value == null) {
          expect(res, isEmpty, reason: 'Failed for ${entry.key}');
        } else {
          final expected = entry.value!;
          expect(res, isNotEmpty, reason: 'Failed for ${entry.key}');
          expect(res.first.book.id, expected.$1, reason: 'Wrong book for ${entry.key}');
          expect(res.first.chapter, expected.$2, reason: 'Wrong chapter for ${entry.key}');
          expect(res.first.verse, expected.$3, reason: 'Wrong verse for ${entry.key}');
        }
      }
    });
  });
}
