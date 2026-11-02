import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/services/bible_repository_provider.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/core/theme/app_typography.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/constants.dart';
import 'package:bibleflutter/features/crossref/data/models/cross_ref.dart';
import 'package:bibleflutter/features/crossref/data/repositories/crossref_repository.dart';
import 'package:bibleflutter/features/crossref/presentation/widgets/cross_ref_sheet.dart';
import 'package:bibleflutter/features/crossref/providers/crossref_providers.dart';

/// An in-memory database with the schema `tool/build_crossrefs.dart` writes.
Database _fixture(List<List<Object>> rows) {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE cross_ref (
      book TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL,
      to_book TEXT NOT NULL, to_chapter INTEGER NOT NULL, to_verse INTEGER NOT NULL,
      to_chapter_end INTEGER NOT NULL, to_verse_end INTEGER NOT NULL,
      votes INTEGER NOT NULL,
      PRIMARY KEY (book, chapter, verse, to_book, to_chapter, to_verse)
    ) WITHOUT ROWID;
  ''');
  final insert = db.prepare('INSERT INTO cross_ref VALUES (?,?,?,?,?,?,?,?,?)');
  for (final row in rows) {
    insert.execute(row);
  }
  insert.close();
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late BibleStorage storage;
  late BibleRepository bibleRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('cross_ref_test');
    storage = BibleStorage(rootOverride: tmpDir);
    bibleRepo = BibleRepository(storage: storage);
    await bibleRepo.init();
  });

  tearDown(() async {
    bibleRepo.dispose();
    if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
  });

  group('CrossRef', () {
    test('a single verse is not a range', () {
      const r = CrossRef(book: 'ROM', chapter: 5, verse: 8, votes: 3);
      expect(r.isRange, isFalse);
      expect(r.toChapter, 5);
      expect(r.toVerse, 8);
    });

    test('equal fields make equal keys, so providers cache per target', () {
      const a = CrossRef(book: '1JN', chapter: 4, verse: 9, toVerse: 10, votes: 7);
      const b = CrossRef(book: '1JN', chapter: 4, verse: 9, toVerse: 10, votes: 7);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isRange, isTrue);
    });
  });

  group('CrossRefRepository', () {
    test('returns links for a verse, most-voted first', () async {
      final repo = CrossRefRepository(open: () async => _fixture([
            ['JHN', 3, 16, '1JN', 4, 9, 4, 10, 7],
            ['JHN', 3, 16, 'ROM', 5, 8, 5, 8, 9],
          ]));
      final refs = await repo.getCrossRefs('JHN', 3, 16);
      expect(refs.map((r) => r.book), ['ROM', '1JN']);
      expect(refs.last.toVerse, 10);
      await repo.close();
    });

    test('a verse nobody linked returns an empty list', () async {
      final repo = CrossRefRepository(open: () async => _fixture([]));
      expect(await repo.getCrossRefs('JHN', 1, 1), isEmpty);
      await repo.close();
    });

    test('a broken database reads as no references, not a crash', () async {
      final repo = CrossRefRepository(
          open: () async => throw const FileSystemException('missing'));
      expect(await repo.getCrossRefs('JHN', 3, 16), isEmpty);
    });
  });

  group('bundled crossrefs.db.gz', () {
    late CrossRefRepository repo;

    setUp(() async {
      final file = await storage.ensureCrossRefsInstalled();
      repo = CrossRefRepository(
          open: () async => sqlite3.open(file.path, mode: OpenMode.readOnly));
    });

    tearDown(() => repo.close());

    test('John 3:16 leads with Romans 5:8', () async {
      final refs = await repo.getCrossRefs('JHN', 3, 16);
      expect(refs.first.book, 'ROM');
      expect((refs.first.chapter, refs.first.verse), (5, 8));
    });

    // am-2000 numbers Psalms the Greek way: "The Lord is my shepherd" is its
    // Psalm 22. In KJV numbering the shepherd links would land on Psalm 23,
    // which in this Bible is "The earth is the Lord's".
    test('Psalm references follow am-2000 numbering', () async {
      final shepherd = await repo.getCrossRefs('PSA', 22, 1);
      expect(shepherd.any((r) => r.book == 'JHN' && r.chapter == 10 && r.verse == 11),
          isTrue);
      final earth = await repo.getCrossRefs('PSA', 23, 1);
      expect(earth.any((r) => r.book == '1CO' && r.chapter == 10 && r.verse == 26),
          isTrue);
    });

    test('a second install with the same stamp keeps the file', () async {
      final first = await storage.ensureCrossRefsInstalled();
      final modified = first.lastModifiedSync();
      final second = await storage.ensureCrossRefsInstalled();
      expect(second.lastModifiedSync(), modified);
    });
  });

  group('CrossRefSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      CrossRefRepository repo, {
      void Function(String, int, int)? onSelect,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            crossRefRepositoryProvider.overrideWithValue(repo),
            bibleRepositoryProvider.overrideWithValue(bibleRepo),
          ],
          child: BibleRepositoryProvider(
            repository: bibleRepo,
            child: Settings(
              notifier: ValueNotifier(const AppSettings()),
              child: L10n(
                initialLanguage: AppLanguage.english,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: Scaffold(
                    body: CrossRefSheet(
                      sourceBook: 'JHN',
                      sourceChapter: 3,
                      sourceVerse: 16,
                      sourceReferenceLabel: 'John 3:16',
                      onSelectCrossRef: onSelect ?? (_, _, _) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the source verse and a close button', (tester) async {
      final repo = CrossRefRepository(open: () async => _fixture([]));
      await pumpSheet(tester, repo);
      expect(find.text('John 3:16'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('a card names its passage, shows votes, and opens it', (tester) async {
      final repo = CrossRefRepository(open: () async => _fixture([
            ['JHN', 3, 16, 'ROM', 5, 8, 5, 8, 980],
          ]));
      String? book;
      int? chapter, verse;
      await pumpSheet(tester, repo, onSelect: (b, c, v) {
        book = b;
        chapter = c;
        verse = v;
      });

      expect(find.textContaining('5:8'), findsOneWidget);
      expect(find.text('980'), findsOneWidget);

      await tester.tap(find.textContaining('5:8'));
      await tester.pumpAndSettle();
      expect((book, chapter, verse), ('ROM', 5, 8));
    });
  });

  test('Noto Sans Ethiopic is offered as a reader font', () {
    expect(readerFonts, contains(AppTypography.notoSansEthiopic));
    expect(readerFontNames, contains('ኖቶ ሳንስ'));
    expect(readerFonts.length, readerFontNames.length);
  });
}
