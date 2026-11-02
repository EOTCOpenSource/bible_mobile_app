// ignore_for_file: invalid_use_of_visible_for_testing_member, avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/models/book_introduction.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final tmpDir = await Directory.systemTemp.createTemp('intro_report_gen');
  try {
    final storage = BibleStorage(rootOverride: tmpDir);
    final repo = BibleRepository(storage: storage);
    await repo.init();
    await repo.loadIntroductions();

    final index = await repo.loadIndex();
    final intros = repo.getAllIntroductions();

    final buffer = StringBuffer();
    buffer.writeln('# Book Introduction Mapping Verification Report');
    buffer.writeln();
    buffer.writeln('**Generated:** ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('| Book # | Book Name (Am/En) | Status |');
    buffer.writeln('| :---: | :--- | :---: |');

    int passCount = 0;
    int missingCount = 0;
    int wrongCount = 0;

    for (final book in index) {
      final bNum = book.bookNumber;
      final intro = intros[bNum];

      String statusStr;
      if (intro == null) {
        statusStr = '❌ MISSING';
        missingCount++;
      } else {
        final introBlob = _getIntroTextBlob(intro);
        final keywords = _getBookKeywords(book);
        final hasMatch = keywords.any((kw) => introBlob.contains(kw));
        if (hasMatch) {
          statusStr = '✅ PASS';
          passCount++;
        } else {
          statusStr = '❌ WRONG CONTENT';
          wrongCount++;
        }
      }

      buffer.writeln('| $bNum | ${book.bookNameAm} (${book.bookNameEn}) | $statusStr |');
    }

    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('- **Total Canonical Books:** ${index.length}');
    buffer.writeln('- **Passed:** $passCount');
    buffer.writeln('- **Missing:** $missingCount');
    buffer.writeln('- **Wrong Content:** $wrongCount');
    buffer.writeln();
    if (missingCount == 0 && wrongCount == 0) {
      buffer.writeln('**Final Result:** ✅ ALL BOOK INTRODUCTIONS CORRECTLY MAPPED');
    } else {
      buffer.writeln('**Final Result:** ❌ INTRODUCTIONS MAPPING ISSUES DETECTED');
    }

    final reportPath = 'introduction_mapping_report.md';
    await File(reportPath).writeAsString(buffer.toString());
    print(buffer.toString());
    print('\nReport saved to: $reportPath');
  } finally {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  }
}

List<String> _getBookKeywords(BookIndexEntry book) {
  final keywords = <String>{};

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

  final enClean = book.bookNameEn
      .replaceAll(RegExp(r'^\d\s*'), '')
      .replaceAll(RegExp(r'^(Book of|Rest of)\s*', caseSensitive: false), '')
      .trim();
  if (enClean.isNotEmpty) {
    keywords.add(enClean);
  }

  return keywords.toList();
}

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
