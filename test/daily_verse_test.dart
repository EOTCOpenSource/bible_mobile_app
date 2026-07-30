import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late BibleRepository repo;

  // The repository now reads SQLite out of app support, which `path_provider`
  // cannot supply under test — unpack the bundled edition into a temp dir.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('bibleflutter_daily');
    repo = BibleRepository(storage: BibleStorage(rootOverride: tmp));
    await repo.init();
  });

  tearDownAll(() {
    repo.dispose();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('every Ethiopian day of the year resolves to a real verse', () async {
    final failures = <String>[];

    // 12 months of 30 days + Pagume (6 days in a leap year).
    for (var month = 1; month <= 13; month++) {
      final days = month == 13 ? 6 : 30;
      for (var day = 1; day <= days; day++) {
        final result = await repo.loadDailyVerse(month, day);
        if (result == null || result.text.trim().isEmpty) {
          failures.add('$month/$day');
        }
      }
    }

    expect(failures, isEmpty,
        reason: 'days with no daily verse: ${failures.join(", ")}');
  });

  test('book names that differ from the catalog still resolve', () async {
    // The curated file uses Ethiopian short names ("Kufale", "Yodit",
    // "Ezra Sutuel", "Act", "Sirach", "Tobit") that match neither the USFM id
    // nor the English name. Each of these days used to render blank.
    const aliasDays = <String, List<int>>{
      'Kufale':      [1, 6],
      'Sirach':      [2, 15],
      'Tobit':       [3, 11],
      'Act':         [5, 1],
      'Yodit':       [8, 11],
      'Ezra Sutuel': [11, 11],
    };

    for (final entry in aliasDays.entries) {
      final result =
          await repo.loadDailyVerse(entry.value[0], entry.value[1]);
      expect(result, isNotNull, reason: '${entry.key} did not resolve');
      expect(result!.text.trim(), isNotEmpty, reason: entry.key);
      expect(result.bookNameAm, isNotEmpty, reason: entry.key);
    }
  });

  test('Pagume and other uncovered days still return a verse', () async {
    for (final day in [1, 2, 3, 4, 5, 6]) {
      final result = await repo.loadDailyVerse(13, day);
      expect(result, isNotNull, reason: 'Pagume $day');
      expect(result!.text.trim(), isNotEmpty, reason: 'Pagume $day');
    }
  });
}
