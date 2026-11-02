import 'dart:io';

import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/edition_database.dart';
import 'package:bibleflutter/features/books/data/models/book.dart';
import 'package:bibleflutter/features/books/data/models/book_identity.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises the SQLite reading layer against the real bundled `am-2000`
/// database, unpacked into a temp directory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late BibleRepository repo;

  setUpAll(() async {
    // The active-edition choice is persisted; tests start with none set.
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('bibleflutter_test');
    repo = BibleRepository(storage: BibleStorage(rootOverride: tmp));
    await repo.init();
  });

  tearDownAll(() async {
    repo.dispose();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('book index', () {
    test('loads the bundled edition with USFM ids', () async {
      final index = await repo.loadIndex();

      expect(repo.activeEditionId, 'am-2000');
      expect(index, hasLength(89));
      expect(index.first.id, 'GEN');
      expect(index.map((e) => e.id), contains('REV'));
      // The Ethiopic appendix the legacy JSON never had.
      expect(index.map((e) => e.id), contains('XXC'));
    });

    test('names come from the catalog in both UI languages', () async {
      final gen = await repo.bookById('GEN');

      expect(gen, isNotNull);
      expect(gen!.bookNameAm, 'ኦሪት ዘፍጥረት');
      expect(gen.bookNameEn, 'Genesis');
      // The catalog has no English abbreviations at all, so this has to come
      // from the frozen table or it would render as Ethiopic.
      expect(gen.bookShortNameEn, 'Gen');
      expect(gen.bookShortNameAm, isNot(equals(gen.bookShortNameEn)));
    });

    test('canon sections are populated for the books-tab filters', () async {
      final index = await repo.loadIndex();
      final sections = index.map((e) => e.section).toSet();

      expect(sections, contains('Pentateuch'));
      expect(sections, contains('Gospel'));
      expect(sections, contains('MinorProphet'));
      // The appendix is deliberately unsectioned — it is what "other" catches.
      expect(sections, contains(null));

      final pentateuch =
          index.where((e) => e.section == 'Pentateuch').map((e) => e.id);
      expect(pentateuch, ['GEN', 'EXO', 'LEV', 'NUM', 'DEU']);
    });
  });

  group('chapter loading', () {
    test('Genesis 1 has verses, headings and cross references', () async {
      final gen = (await repo.bookById('GEN'))!;
      final book = await repo.loadBook(gen);
      final ch1 = book.chapters.first;

      expect(ch1.chapterNumber, 1);
      expect(ch1.allVerses, hasLength(31));

      final v1 = ch1.allVerses.first;
      expect(v1.verseNumber, 1);
      expect(v1.label, '1');
      expect(v1.alt, '፩'); // Ge'ez numeral straight from the database
      expect(v1.text, startsWith('በመጀመሪያ እግዚአብሔር'));
      expect(v1.refs, isNotEmpty);
      expect(v1.refs.first.target, contains('ኢዮብ'));

      // The section title is the `s1` heading; the `ms1` chapter marker is
      // carried but not used as a title.
      expect(ch1.sections.first.title, 'የፍጥረት ታሪክ');
      expect(
        ch1.sections.first.ofKind(HeadingKind.major).map((h) => h.text),
        contains('ምዕራፍ 1'),
      );
    });

    test('verses are ordered by ord and cover the whole book', () async {
      final gen = (await repo.bookById('GEN'))!;
      final book = await repo.loadBook(gen);

      expect(book.chapters, hasLength(50));
      final total =
          book.chapters.fold<int>(0, (n, c) => n + c.allVerses.length);
      expect(total, 1533); // matches book.verses in the database

      for (final chapter in book.chapters) {
        final ords = chapter.allVerses.map((v) => v.ord).toList();
        expect(ords, orderedEquals(List.of(ords)..sort()),
            reason: 'chapter ${chapter.chapterNumber} is out of order');
      }
    });

    test('poetry verses expose lines that re-join to the verse text',
        () async {
      final exo = (await repo.bookById('EXO'))!;
      final book = await repo.loadBook(exo);
      final ch15 = book.chapters.firstWhere((c) => c.chapterNumber == 15);
      final v1 = ch15.allVerses.firstWhere((v) => v.verseNumber == 1);

      expect(v1.lines.length, greaterThan(1));
      expect(v1.lines.any((l) => l.indent > 0), isTrue,
          reason: 'the song of Moses should have indented poetic lines');
      // `lines` duplicates `text`; rendering both would print the verse twice.
      expect(v1.lines.map((l) => l.text).join(' '), v1.text);
    });

    test('every verse of every book has a usable display number', () async {
      // ~100 verses across the corpus carry only a cross reference and have no
      // number. They must not collide with real verse numbers.
      final psa = (await repo.bookById('PSA'))!;
      final book = await repo.loadBook(psa);

      for (final chapter in book.chapters) {
        for (final v in chapter.allVerses) {
          if (v.isNumbered) {
            expect(v.verseNumber, greaterThan(0));
            expect(v.displayNumber(useGeez: false), isNotEmpty);
          } else {
            expect(v.verseNumber, lessThan(0));
            expect(v.displayNumber(useGeez: false), isEmpty);
          }
        }
      }
    });
  });

  group('search', () {
    test('finds fasting verses with a trigram length topic keyword', () async {
      final hits = await repo.searchVerses('በጾም');

      expect(hits, isNotEmpty);
    });

    test('trigram index finds an agglutinated Amharic word', () async {
      final hits = await repo.searchVerses('እግዚአብሔር');

      expect(hits, isNotEmpty);
      // Trigram matches inside inflected forms, which a word tokenizer misses.
      expect(hits.every((h) => h.text.contains('እግዚአብሔር')), isTrue);
      expect(hits.first.bookEntry.id, isNotEmpty);
    });

    test('scoping to one book restricts the results', () async {
      final gen = (await repo.bookById('GEN'))!;
      final hits = await repo.searchVerses(
        'እግዚአብሔር',
        filter: SearchFilter(book: gen),
      );

      expect(hits, isNotEmpty);
      expect(hits.every((h) => h.bookEntry.id == 'GEN'), isTrue);
    });

    test('new-testament scope excludes the deuterocanon', () async {
      final hits = await repo.searchVerses(
        'ኢየሱስ',
        filter: const SearchFilter(scope: SearchScope.newTestament),
      );

      expect(hits, isNotEmpty);
      expect(hits.every((h) => h.bookEntry.isNewTestament), isTrue);
    });

    test('FTS operators in user input do not throw', () async {
      // `-`, `*`, `:`, AND/OR/NEAR are FTS5 syntax; unquoted they are a parse
      // error rather than a search.
      for (final q in ['ሰው-', 'a*b', 'AND', 'x OR y', 'a:b', 'he said "no"']) {
        expect(() async => repo.searchVerses(q), returnsNormally,
            reason: 'query "$q" should be escaped, not fatal');
        await repo.searchVerses(q);
      }
    });

    test('quotes the term as a literal phrase', () {
      expect(EditionDatabase.ftsQuery('ሰው-', allWords: false), '"ሰው-"');
      expect(
        EditionDatabase.ftsQuery('a b', allWords: true),
        '"a" AND "b"',
      );
      // Internal quotes are doubled, which is how FTS5 escapes them.
      expect(
        EditionDatabase.ftsQuery('say "hi"', allWords: false),
        '"say ""hi"""',
      );
    });
  });

  group('book identity', () {
    test('USFM survives a round trip through the API vocabulary', () {
      for (final usfm in kUsfmToLegacyName.keys) {
        final api = apiBookIdFromUsfm(usfm);
        expect(usfmFromAnyBookId(api), usfm, reason: 'api id "$api"');
        expect(usfmFromAnyBookId(kUsfmToLegacyName[usfm]!), usfm);
        expect(usfmFromAnyBookId(usfm), usfm);
      }
    });

    test('the frozen wire format matches what the server already stores', () {
      // These are the exact kebab ids the web frontend has written. Changing
      // any of them orphans real annotations.
      expect(apiBookIdFromUsfm('GEN'), 'genesis');
      expect(apiBookIdFromUsfm('1SA'), '1-samuel');
      expect(apiBookIdFromUsfm('TOB'), 'book-of-tobit');
      expect(apiBookIdFromUsfm('SIR'), 'book-of-sirach');
      expect(apiBookIdFromUsfm('LJE'), 'thr-letter-of-jeremiah');
      expect(apiBookIdFromUsfm('1ES'), '3-book-of-ezra');
      expect(apiBookIdFromUsfm('2ES'), '2nd-book-of-ezra');
      expect(apiBookIdFromUsfm('4MA'), 'book-of-admonition');
    });

    test('deep link slugs are stable and reversible', () {
      expect(deepLinkSlugFromUsfm('JER'), 'jer');
      expect(deepLinkSlugFromUsfm('1SA'), '1sam');
      expect(deepLinkSlugFromUsfm('PSA'), 'ps');
      for (final usfm in kUsfmToEnAbbrev.keys) {
        expect(usfmFromDeepLinkSlug(deepLinkSlugFromUsfm(usfm)), usfm);
      }
    });

    test('an unmappable book id is preserved, not reassigned', () {
      // ተረፈ ባሮክ has no slot in the 80-weahadu canon. Silently mapping it onto
      // BAR or LJE would move a reader's notes into a different book.
      expect(usfmFromAnyBookId('Teref Baruch'), 'Teref Baruch');
      expect(kLegacyNameToUsfm.containsKey('teref baruch'), isFalse);
    });
  });

  group('parallel reading', () {
    // A byte copy of the bundled edition installed under a second id. The other
    // eight editions are downloads, so this is the only way to exercise two
    // open databases without a network.
    const parallelId = 'am-2000-parallel';

    setUpAll(() async {
      final source = await repo.storage.editionFile(
        BibleStorage.bundledEditionId,
      );
      final target = await repo.storage.editionFile(parallelId);
      source.copySync(target.path);
    });

    tearDown(() async {
      await repo.setSecondaryEdition(null);
      await repo.switchEdition(BibleStorage.bundledEditionId);
    });

    test('is off until an edition is put in the second column', () {
      expect(repo.secondaryEditionId, isNull);
      expect(repo.isParallelReading, isFalse);
    });

    test('refuses an edition that is not installed', () async {
      expect(await repo.setSecondaryEdition('en-kjv'), isFalse);
      expect(repo.secondaryEditionId, isNull);
    });

    test('refuses the edition already being read', () async {
      expect(
        await repo.setSecondaryEdition(BibleStorage.bundledEditionId),
        isFalse,
      );
      expect(repo.secondaryEditionId, isNull);
    });

    test('reads the same book out of the second edition', () async {
      expect(await repo.setSecondaryEdition(parallelId), isTrue);
      expect(repo.isParallelReading, isTrue);

      final secondary = await repo.loadSecondaryBook('GEN');
      expect(secondary, isNotNull);
      expect(secondary!.chapters, hasLength(50));
      expect(secondary.chapters.first.allVerses, hasLength(31));

      // The primary is untouched by any of this — the parallel column is a
      // read, not a switch.
      expect(repo.activeEditionId, BibleStorage.bundledEditionId);
      final primary = await repo.loadBook((await repo.bookById('GEN'))!);
      expect(
        secondary.chapters.first.allVerses.first.text,
        primary.chapters.first.allVerses.first.text,
      );
    });

    test('a book the parallel canon does not carry resolves to null', () async {
      await repo.setSecondaryEdition(parallelId);
      expect(await repo.loadSecondaryBook('ZZZ'), isNull);
    });

    test('returns null for every book while parallel reading is off', () async {
      expect(repo.secondaryEditionId, isNull);
      expect(await repo.loadSecondaryBook('GEN'), isNull);
    });

    test('reading the parallel edition drops it from the second column',
        () async {
      await repo.setSecondaryEdition(parallelId);
      expect(await repo.switchEdition(parallelId), isTrue);

      // An edition cannot be both columns.
      expect(repo.activeEditionId, parallelId);
      expect(repo.secondaryEditionId, isNull);
      expect(await repo.loadSecondaryBook('GEN'), isNull);
    });

    test('deleting the parallel edition turns parallel reading off', () async {
      await repo.setSecondaryEdition(parallelId);
      await repo.storage.deleteEdition(parallelId);
      await repo.handleEditionRemoved(parallelId);

      expect(repo.secondaryEditionId, isNull);
      // The primary was never the deleted edition, so it stays put.
      expect(repo.activeEditionId, BibleStorage.bundledEditionId);
    });
  });

  group('daily verse', () {
    test('curated book aliases resolve to the right book', () async {
      // The curated file names books by canon slug and abbreviation rather
      // than by the English name. The full-year sweep lives in
      // daily_verse_test.dart.
      const aliases = {
        'Kufale': 'JUB',
        'Yodit': 'JDT',
        'Ezra Sutuel': '1ES',
        'Act': 'ACT',
        'Sirach': 'SIR',
        'Tobit': 'TOB',
        'Enoch': 'ENO',
        'Wisdom of Solomon': 'WIS',
        'Song of Solomon': 'SNG',
        '1 Corinthians': '1CO',
      };
      for (final entry in aliases.entries) {
        final book = await repo.resolveBook(entry.key);
        expect(book?.id, entry.value, reason: 'alias "${entry.key}"');
      }
    });
  });
}
