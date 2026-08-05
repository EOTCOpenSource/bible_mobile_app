// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';

void main() {
  test('print all 81 books', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final tmp = await Directory.systemTemp.createTemp('bibleflutter_test');
    final repo = BibleRepository(storage: BibleStorage(rootOverride: tmp));
    await repo.init();
    final index = await repo.loadIndex();
    print('INDEX_BOOK_NUMBERS: ${index.map((e) => e.bookNumber).toList()}');
    for (final e in index) {
      print('${e.bookNumber}: ${e.id} (${e.bookNameAm} / ${e.bookNameEn})');
    }
  });
}
