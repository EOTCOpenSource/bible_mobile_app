import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/annotations/annotation_models.dart';

void main() {
  group('Annotation Models & SyncStatus', () {
    test('Bookmark serialization toMap and fromMap', () {
      final now = DateTime.now();
      final bookmark = Bookmark(
        id: 42,
        bookId: 'GEN',
        bookNumber: 1,
        chapter: 1,
        verseStart: 1,
        verseCount: 5,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
        remoteId: 'remote-123',
      );

      final map = bookmark.toMap();
      expect(map['id'], 42);
      expect(map['book_id'], 'GEN');
      expect(map['sync_status'], 'pendingCreate');
      expect(map['remote_id'], 'remote-123');

      final deserialized = Bookmark.fromMap(map);
      expect(deserialized.id, 42);
      expect(deserialized.bookId, 'GEN');
      expect(deserialized.syncStatus, SyncStatus.pendingCreate);
      expect(deserialized.remoteId, 'remote-123');
    });

    test('SyncStatus enum values', () {
      expect(SyncStatus.values.length, 4);
      expect(SyncStatus.pendingCreate.name, 'pendingCreate');
      expect(SyncStatus.pendingUpdate.name, 'pendingUpdate');
      expect(SyncStatus.pendingDelete.name, 'pendingDelete');
      expect(SyncStatus.synced.name, 'synced');
    });
  });
}
