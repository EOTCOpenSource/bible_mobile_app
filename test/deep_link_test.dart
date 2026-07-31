import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/deep_links/deep_link_uri.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';

void main() {
  group('Deep Link URI Parsing', () {
    final mockIndex = [
      const BookIndexEntry(
        id: 'GEN',
        bookNumber: 1,
        bookNameAm: 'ኦሪት ዘፍጥረት',
        bookNameEn: 'Genesis',
        bookShortNameAm: 'ዘፍ',
        bookShortNameEn: 'Gen',
        testament: 'old',
        chapterCount: 50,
      ),
      const BookIndexEntry(
        id: '1SA',
        bookNumber: 9,
        bookNameAm: 'መጽሐፈ ሳሙኤል ቀዳማዊ',
        bookNameEn: '1 Samuel',
        bookShortNameAm: '1 ሳሙ',
        bookShortNameEn: '1 Sam',
        testament: 'old',
        chapterCount: 31,
      ),
      const BookIndexEntry(
        id: 'JER',
        bookNumber: 24,
        bookNameAm: 'ትንቢተ ኤርምያስ',
        bookNameEn: 'Jeremiah',
        bookShortNameAm: 'ኤር',
        bookShortNameEn: 'Jer',
        testament: 'old',
        chapterCount: 52,
      ),
    ];

    test('verseDeepLinkSlug encodes correctly', () {
      final slug = verseDeepLinkSlug(mockIndex[2], 29, 11);
      expect(slug, 'jer29_11');

      final samSlug = verseDeepLinkSlug(mockIndex[1], 17, 4);
      expect(samSlug, '1sam17_4');
    });

    test('parseDeepLink handles valid HTTPS app link', () {
      final uri = Uri.parse('https://80-weahadu.vercel.app/openinapp/jer29_11');
      final target = parseDeepLink(uri, mockIndex);
      expect(target, isNotNull);
      expect(target!.entry.bookNameEn, 'Jeremiah');
      expect(target.chapter, 29);
      expect(target.verse, 11);
    });

    test('parseDeepLink handles valid eotcbible custom scheme', () {
      final uri = Uri.parse('eotcbible://openinapp/1sam17_4');
      final target = parseDeepLink(uri, mockIndex);
      expect(target, isNotNull);
      expect(target!.entry.bookNameEn, '1 Samuel');
      expect(target.chapter, 17);
      expect(target.verse, 4);
    });

    test('parseDeepLink returns null for malformed or unknown inputs', () {
      // Unknown book
      expect(parseDeepLink(Uri.parse('https://80-weahadu.vercel.app/openinapp/xyz1_1'), mockIndex), isNull);

      // Wrong host / scheme
      expect(parseDeepLink(Uri.parse('https://example.com/openinapp/jer29_11'), mockIndex), isNull);

      // Empty path
      expect(parseDeepLink(Uri.parse('eotcbible://openinapp'), mockIndex), isNull);
    });
  });
}
