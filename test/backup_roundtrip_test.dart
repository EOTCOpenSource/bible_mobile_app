import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bibleflutter/core/annotations/annotation_models.dart';
import 'package:bibleflutter/core/storage/app_database.dart';
import 'package:bibleflutter/features/backup/data/backup_models.dart';
import 'package:bibleflutter/features/backup/data/export_service.dart';
import 'package:bibleflutter/features/backup/data/import_service.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmpDir;
  late AppDatabase db;
  late BibleRepository bibleRepo;
  late ExportService exportService;
  late ImportService importService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('backup_test');
    db = AppDatabase();

    // Clear tables before each test
    final dbInstance = await db.database;
    await dbInstance.delete('bookmarks');
    await dbInstance.delete('highlights');
    await dbInstance.delete('notes');

    bibleRepo = BibleRepository(storage: BibleStorage(rootOverride: tmpDir));
    await bibleRepo.init();

    exportService = ExportService(db: db, bibleRepository: bibleRepo);
    importService = ImportService(db: db, bibleRepository: bibleRepo);
  });

  tearDown(() async {
    bibleRepo.dispose();
    await db.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  group('Backup & Restore Roundtrip Tests', () {
    test('JSON Backup roundtrip succeeds and preserves annotations', () async {
      final now = DateTime.now();
      final bm = Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        createdAt: now,
        updatedAt: now,
      );
      final hl = Highlight(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        color: const Color(0xFFFFE082),
        createdAt: now,
        updatedAt: now,
      );
      final nt = Note(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        content: 'In the beginning test note',
        createdAt: now,
        updatedAt: now,
      );

      await db.insertBookmark(bm);
      await db.insertHighlight(hl);
      await db.insertNote(nt);

      final initialBookmarks = await db.getAllBookmarks();
      final initialHighlights = await db.getAllHighlights();
      final initialNotes = await db.getAllNotes();

      expect(initialBookmarks, hasLength(1));
      expect(initialHighlights, hasLength(1));
      expect(initialNotes, hasLength(1));

      // 2. Export to JSON
      final exportFile = File('${tmpDir.path}/export.json');
      await exportService.exportToJson(exportFile);
      expect(exportFile.existsSync(), isTrue);

      final jsonString = await exportFile.readAsString();
      expect(jsonString, contains('"formatVersion": 1'));
      expect(jsonString, contains('genesis'));
      expect(jsonString, contains('In the beginning test note'));

      // 3. Clear local database
      await db.deleteBookmark(initialBookmarks.first.id!);
      await db.deleteHighlight(initialHighlights.first.id!);
      await db.deleteNote(initialNotes.first.id!);

      expect(await db.getAllBookmarks(), isEmpty);
      expect(await db.getAllHighlights(), isEmpty);
      expect(await db.getAllNotes(), isEmpty);

      // 4. Parse & Import
      final preview = await importService.parseAndPreview(jsonString);
      expect(preview.bookmarkCount, 1);
      expect(preview.highlightCount, 1);
      expect(preview.noteCount, 1);
      expect(preview.existingCount, 0);

      await importService.executeImport(
        payload: preview.payload,
        conflictPolicy: BackupConflictPolicy.skip,
      );

      // 5. Assert database contents match original
      final restoredBookmarks = await db.getAllBookmarks();
      final restoredHighlights = await db.getAllHighlights();
      final restoredNotes = await db.getAllNotes();

      expect(restoredBookmarks, hasLength(1));
      expect(restoredBookmarks.first.bookId, 'GEN');
      expect(restoredBookmarks.first.chapter, 1);
      expect(restoredBookmarks.first.verseStart, 1);

      expect(restoredHighlights, hasLength(1));
      expect(restoredHighlights.first.bookId, 'GEN');
      expect(restoredHighlights.first.color.toARGB32(), const Color(0xFFFFE082).toARGB32());

      expect(restoredNotes, hasLength(1));
      expect(restoredNotes.first.bookId, 'GEN');
      expect(restoredNotes.first.content, 'In the beginning test note');
    });

    test('Empty database export and import roundtrip', () async {
      final exportFile = File('${tmpDir.path}/empty.json');
      await exportService.exportToJson(exportFile);

      final jsonString = await exportFile.readAsString();
      final preview = await importService.parseAndPreview(jsonString);

      expect(preview.bookmarkCount, 0);
      expect(preview.highlightCount, 0);
      expect(preview.noteCount, 0);
      expect(preview.existingCount, 0);

      await importService.executeImport(
        payload: preview.payload,
        conflictPolicy: BackupConflictPolicy.skip,
      );

      expect(await db.getAllBookmarks(), isEmpty);
      expect(await db.getAllHighlights(), isEmpty);
      expect(await db.getAllNotes(), isEmpty);
    });

    test('Unsupported formatVersion throws exception and leaves database untouched', () async {
      final now = DateTime.now();
      await db.insertBookmark(Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        createdAt: now,
        updatedAt: now,
      ));
      final countBefore = (await db.getAllBookmarks()).length;

      const malformedJson = '''
      {
        "formatVersion": 99,
        "exportedAt": "2026-07-27T10:00:00Z",
        "appVersion": "1.0.0+1",
        "bookmarks": [],
        "highlights": [],
        "notes": []
      }
      ''';

      expect(
        () => importService.parseAndPreview(malformedJson),
        throwsA(isA<FormatException>()),
      );

      final countAfter = (await db.getAllBookmarks()).length;
      expect(countAfter, equals(countBefore));
    });

    test('Conflict policy - Replace overwrites existing note', () async {
      final now = DateTime.now();
      await db.insertNote(Note(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        content: 'Original Note',
        createdAt: now,
        updatedAt: now,
      ));

      const jsonWithNote = '''
      {
        "formatVersion": 1,
        "exportedAt": "2026-07-27T10:00:00Z",
        "appVersion": "1.0.0+1",
        "bookmarks": [],
        "highlights": [],
        "notes": [
          { "bookId": "genesis", "chapter": 1, "verse": 1, "body": "Replaced Note", "createdAt": 1000, "updatedAt": 1000 }
        ]
      }
      ''';

      final preview = await importService.parseAndPreview(jsonWithNote);
      expect(preview.existingCount, 1);

      await importService.executeImport(
        payload: preview.payload,
        conflictPolicy: BackupConflictPolicy.replace,
      );

      final notes = await db.getAllNotes();
      expect(notes, hasLength(1));
      expect(notes.first.content, 'Replaced Note');
    });

    test('Conflict policy - Merge concatenates note body', () async {
      final now = DateTime.now();
      await db.insertNote(Note(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        content: 'Original Note',
        createdAt: now,
        updatedAt: now,
      ));

      const jsonWithNote = '''
      {
        "formatVersion": 1,
        "exportedAt": "2026-07-27T10:00:00Z",
        "appVersion": "1.0.0+1",
        "bookmarks": [],
        "highlights": [],
        "notes": [
          { "bookId": "genesis", "chapter": 1, "verse": 1, "body": "Appended Note", "createdAt": 1000, "updatedAt": 1000 }
        ]
      }
      ''';

      final preview = await importService.parseAndPreview(jsonWithNote);
      await importService.executeImport(
        payload: preview.payload,
        conflictPolicy: BackupConflictPolicy.merge,
      );

      final notes = await db.getAllNotes();
      expect(notes, hasLength(1));
      expect(notes.first.content, 'Original Note\n\nAppended Note');
    });

    test('Markdown export creates valid file with headers and verses', () async {
      final now = DateTime.now();
      await db.insertNote(Note(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        content: 'Creation Note',
        createdAt: now,
        updatedAt: now,
      ));

      final mdFile = File('${tmpDir.path}/export.md');
      await exportService.exportToMarkdown(mdFile);

      expect(mdFile.existsSync(), isTrue);
      final mdContent = await mdFile.readAsString();

      expect(mdContent, contains('ኦሪት ዘፍጥረት'));
      expect(mdContent, contains('ምዕራፍ 1'));
      expect(mdContent, contains('Creation Note'));
    });
  });
}
