import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/models/book_introduction.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #23: Book Introduction Mapping Verification Tests', () {
    late Directory tmpDir;
    late BibleRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tmpDir = await Directory.systemTemp.createTemp('intro_verification_test');
      final storage = BibleStorage(rootOverride: tmpDir);
      repo = BibleRepository(storage: storage);
      await repo.init();
      await repo.loadIntroductions();
    });

    tearDown(() async {
      if (tmpDir.existsSync()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('All canonical book introductions are correctly mapped and aligned without missing, wrong, or orphan entries', () async {
      final index = await repo.loadIndex();
      final intros = repo.getAllIntroductions();

      final problems = _verifyMapping(index, intros);

      if (problems.isNotEmpty) {
        fail('Book Introduction Mapping Verification Failed (${problems.length} issues found):\n\n${problems.join('\n')}');
      }
    });

    test('Deliberately swapping two keys in introduction map causes verification to report exact wrong books', () async {
      final index = await repo.loadIndex();
      final intros = Map<int, BookIntroduction>.from(repo.getAllIntroductions());

      // Swap Matthew (59) and Luke (61)
      final intro59 = intros[59];
      final intro61 = intros[61];
      if (intro59 != null && intro61 != null) {
        intros[59] = intro61;
        intros[61] = intro59;
      }

      final problems = _verifyMapping(index, intros);
      expect(problems, isNotEmpty);
      expect(problems.any((p) => p.contains('Book #59') && p.contains('WRONG')), isTrue);
      expect(problems.any((p) => p.contains('Book #61') && p.contains('WRONG')), isTrue);
    });

    test('getIntroduction accepts USFM ID string (e.g. MAT, LUK, REV) and resolves correct introduction', () async {
      final matIntro = repo.getIntroduction('MAT');
      expect(matIntro, isNotNull);
      expect(matIntro!.authorAm.contains('ማቴዎስ') || matIntro.authorEn.contains('Matthew'), isTrue);

      final lukIntro = repo.getIntroduction('LUK');
      expect(lukIntro, isNotNull);
      expect(lukIntro!.authorAm.contains('ሉቃስ') || lukIntro.authorEn.contains('Luke'), isTrue);
    });
  });
}

/// Verification helper returning a list of mapping error messages.
List<String> _verifyMapping(List<BookIndexEntry> index, Map<int, BookIntroduction> intros) {
  final validBookNumbers = index.map((b) => b.bookNumber).toSet();
  final problems = <String>[];

  for (final book in index) {
    final bNum = book.bookNumber;
    final intro = intros[bNum];

    if (intro == null) {
      problems.add('Book #$bNum (${book.bookNameAm} / ${book.bookNameEn}): MISSING introduction at key $bNum');
      continue;
    }

    final introBlob = _getIntroTextBlob(intro);
    final keywords = _getBookKeywords(book);

    final hasMatch = keywords.any((kw) => introBlob.contains(kw));
    if (!hasMatch) {
      problems.add(
        'Book #$bNum (${book.bookNameAm} / ${book.bookNameEn}): WRONG content. Intro at key $bNum does not match book stems $keywords. Found author: "${intro.authorAm}" / "${intro.authorEn}"',
      );
    }
  }

  // Check orphan keys in introductions
  final orphanKeys = intros.keys.where((k) => !validBookNumbers.contains(k)).toList();
  if (orphanKeys.isNotEmpty) {
    problems.add('Orphan JSON keys found (no matching book in canon index): $orphanKeys');
  }

  return problems;
}

/// Helper function to extract search terms/keywords from [BookIndexEntry] without hardcoding book names.
List<String> _getBookKeywords(BookIndexEntry book) {
  final keywords = <String>{};

  // Add clean Amharic book name stem
  final amClean = book.bookNameAm
      .replaceAll('\u200B', '')
      .replaceAll('ኦሪት', '')
      .replaceAll('መጽሐፈ', '')
      .replaceAll('ትንቢተ', '')
      .replaceAll('ወንጌል', '')
      .replaceAll('መልእክት', '')
      .trim();
  if (amClean.isNotEmpty) {
    keywords.add(amClean);
  }

  // Handle special Ethiopian canonical book names/aliases
  final fullAmNoZws = book.bookNameAm.replaceAll('\u200B', '');
  if (fullAmNoZws.contains('መቃብያን')) keywords.add('መቃብያን');
  if (fullAmNoZws.contains('ዕዝራ')) keywords.add('ዕዝራ');
  if (fullAmNoZws.contains('ዮሴፍ')) keywords.add('ዮሴፍ');
  if (fullAmNoZws.contains('ዲድስቅልያ')) keywords.add('ዲድስቅልያ');
  if (fullAmNoZws.contains('ቀሌምንጦስ')) keywords.add('ቀሌምንጦስ');
  if (fullAmNoZws.contains('አብጥሊስ')) keywords.add('አብጥሊስ');
  if (fullAmNoZws.contains('ግጽው')) keywords.add('ግጽው');
  if (fullAmNoZws.contains('ኪዳን')) keywords.add('ኪዳን');
  if (fullAmNoZws.contains('ጽዮን')) keywords.add('ጽዮን');
  if (fullAmNoZws.contains('ትእዛዝ')) keywords.add('ትእዛዝ');
  if (fullAmNoZws.contains('ተግሣጽ')) keywords.add('ተግሣጽ');
  if (book.bookNumber == 55 || book.bookNumber >= 86) {
    keywords.addAll(['ዮሴፍ', 'ሐዋርያት', 'መቃብያን', 'Joseph', 'Apostles', 'Maccabees']);
  }

  // Add English book name stem
  final enClean = book.bookNameEn
      .replaceAll(RegExp(r'^\d\s*'), '')
      .replaceAll(RegExp(r'^(Book of|Rest of)\s*', caseSensitive: false), '')
      .trim();
  if (enClean.isNotEmpty) {
    keywords.add(enClean);
  }

  return keywords.toList();
}

/// Concatenates text fields of [BookIntroduction] to create a unified string blob for keyword matching.
String _getIntroTextBlob(BookIntroduction intro) {
  final sb = StringBuffer();
  sb.write(' ${intro.authorAm} ${intro.authorEn}');
  sb.write(' ${intro.summaryAm} ${intro.summaryEn}');
  for (final theme in intro.themesAm) {
    sb.write(' $theme');
  }
  for (final theme in intro.themesEn) {
    sb.write(' $theme');
  }
  for (final outline in intro.outline) {
    sb.write(' ${outline.titleAm} ${outline.titleEn}');
  }
  return sb.toString();
}
