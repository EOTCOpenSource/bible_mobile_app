import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BibleRepository & JSON Introductions Asset Tests', () {
    late Directory tmpDir;
    late BibleRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tmpDir = await Directory.systemTemp.createTemp('bible_intro_test');
      repo = BibleRepository(storage: BibleStorage(rootOverride: tmpDir));
      await repo.init();
    });

    tearDown(() async {
      if (tmpDir.existsSync()) {
        await tmpDir.delete(recursive: true);
      }
    });

    test('loadIntroductions() parses JSON asset once and populates cache for 81+ books', () async {
      expect(repo.getIntroduction(1), isNotNull);
      expect(repo.getIntroduction(1)!.bookNumber, equals(1));
      expect(repo.getIntroduction(1)!.author, equals('ሙሴ'));
    });

    test('getIntroduction returns correct book for Genesis (1) and last books (81+)', () {
      final gen = repo.getIntroduction(1);
      expect(gen, isNotNull);
      expect(gen!.authorAm, equals('ሙሴ'));

      // Deuterocanonical books
      final tobit = repo.getIntroduction(40);
      expect(tobit, isNotNull);
      expect(tobit!.summaryAm.isNotEmpty, isTrue);

      final enoch = repo.getIntroduction(51);
      expect(enoch, isNotNull);
      expect(enoch!.summaryAm.isNotEmpty, isTrue);

      // Book 81/87 (Revelation)
      final rev = repo.getIntroduction(87) ?? repo.getIntroduction(81);
      expect(rev, isNotNull);
      expect(rev!.summaryAm.isNotEmpty, isTrue);
    });

    test('getIntroduction returns null gracefully for invalid book numbers', () {
      expect(repo.getIntroduction(999), isNull);
      expect(repo.getIntroduction(-1), isNull);
      expect(repo.getIntroduction(0), isNull);
    });

    test('JSON asset contains _comment field and 81+ book entries without crash', () async {
      final file = File('assets/bibledata/introductions.json');
      expect(file.existsSync(), isTrue);

      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded.containsKey('_comment'), isTrue);

      // Filter integer keys
      final bookKeys = decoded.keys.where((k) => int.tryParse(k) != null).toList();
      expect(bookKeys.length, greaterThanOrEqualTo(81));
    });
  });
}
