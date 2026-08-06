import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bibleflutter/core/storage/app_database.dart';
import 'package:bibleflutter/core/annotations/annotation_models.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;

  setUp(() async {
    appDb = AppDatabase();
    final db = await appDb.database;
    await db.delete('collections');
    await db.delete('collection_items');
    await db.delete('bookmarks');
    await db.delete('highlights');
    await db.delete('notes');
  });

  group('Unit Tests — Tag Normalization', () {
    test('normalizeTags handles whitespace, casing, and deduplication correctly', () {
      expect(normalizeTags(' ጾም , prayer , ጾም '), equals('ጾም,prayer'));
      expect(normalizeTags(''), isNull);
      expect(normalizeTags('   '), isNull);
      expect(normalizeTags('A, B, a'), equals('a,b'));
      expect(normalizeTags('fasting, fasting, fasting'), equals('fasting'));
    });
  });

  group('Unit Tests — Collection Model', () {
    test('Collection.copyWith updates fields independently', () {
      final now = DateTime.now();
      final original = Collection(
        id: 1,
        name: 'Original',
        color: Colors.blue,
        icon: 'folder',
        sortOrder: 0,
        createdAt: now,
      );

      final updatedName = original.copyWith(name: 'Updated Name');
      expect(updatedName.name, equals('Updated Name'));
      expect(updatedName.color, equals(Colors.blue));
      expect(updatedName.id, equals(1));

      final updatedColor = original.copyWith(color: Colors.red);
      expect(updatedColor.name, equals('Original'));
      expect(updatedColor.color, equals(Colors.red));
    });
  });

  group('Collections & Tags Repository / Database Tests (Issue #25)', () {
    test('Collection CRUD and reordering succeed', () async {
      final colId1 = await appDb.createCollection('Favorites', color: Colors.blue);
      final colId2 = await appDb.createCollection('Study', color: Colors.green);

      expect(colId1, greaterThan(0));
      expect(colId2, greaterThan(0));

      final collections = await appDb.listCollections();
      expect(collections.length, equals(2));

      final reordered = [collections[1], collections[0]];
      await appDb.reorderCollections(reordered);

      final afterReorder = await appDb.listCollections();
      expect(afterReorder.first.name, equals('Study'));
      expect(afterReorder.first.sortOrder, equals(0));
    });

    test('Adding item to multiple collections and removing from one preserves presence in other', () async {
      final colId1 = await appDb.createCollection('Collection 1');
      final colId2 = await appDb.createCollection('Collection 2');

      final now = DateTime.now();
      final bookmark = Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      await appDb.insertBookmark(bookmark);
      final bookmarks = await appDb.getAllBookmarks();
      final bmId = bookmarks.first.id!;

      await appDb.addItemToCollection(colId1, 'bookmark', bmId);
      await appDb.addItemToCollection(colId2, 'bookmark', bmId);

      final items1 = await appDb.listItemsInCollection(colId1);
      final items2 = await appDb.listItemsInCollection(colId2);

      expect(items1.length, equals(1));
      expect(items2.length, equals(1));

      await appDb.removeItemFromCollection(colId1, 'bookmark', bmId);

      final items1After = await appDb.listItemsInCollection(colId1);
      final items2After = await appDb.listItemsInCollection(colId2);

      expect(items1After.isEmpty, isTrue);
      expect(items2After.length, equals(1));
    });

    test('deleteCollection removes collection & collection_items links without deleting annotations', () async {
      final colId = await appDb.createCollection('Study');

      final now = DateTime.now();
      final bookmark = Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      await appDb.insertBookmark(bookmark);

      final bookmarks = await appDb.getAllBookmarks();
      final bmId = bookmarks.first.id!;

      await appDb.addItemToCollection(colId, 'bookmark', bmId);
      final linkedItems = await appDb.listItemsInCollection(colId);
      expect(linkedItems.length, equals(1));

      await appDb.deleteCollection(colId);

      final collectionsAfter = await appDb.listCollections();
      expect(collectionsAfter.isEmpty, isTrue);

      final itemsAfter = await appDb.listItemsInCollection(colId);
      expect(itemsAfter.isEmpty, isTrue);

      final bookmarksAfter = await appDb.getAllBookmarks();
      expect(bookmarksAfter.length, equals(1));
    });

    test('updateTags normalizes tags before writing to database', () async {
      final now = DateTime.now();
      final bookmark = Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      await appDb.insertBookmark(bookmark);
      final bookmarks = await appDb.getAllBookmarks();
      final bmId = bookmarks.first.id!;

      await appDb.updateTags('bookmark', bmId, '  Fast , FASTING , fast  ');

      final updatedBookmarks = await appDb.getAllBookmarks();
      expect(updatedBookmarks.first.tags, equals('fast,fasting'));
    });

    test('listDistinctTags aggregates tags across bookmarks, highlights, and notes', () async {
      final now = DateTime.now();

      final bookmark = Bookmark(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 1,
        createdAt: now,
        updatedAt: now,
        tags: 'faith, creation',
      );
      await appDb.insertBookmark(bookmark);

      final note = Note(
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 1,
        content: 'Genesis note',
        createdAt: now,
        updatedAt: now,
        tags: 'creation, study',
      );
      await appDb.insertNote(note);

      final distinctTags = await appDb.listDistinctTags();
      expect(distinctTags, equals(['creation', 'faith', 'study']));
    });
  });
}
