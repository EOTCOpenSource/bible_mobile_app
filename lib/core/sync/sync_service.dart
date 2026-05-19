import '../annotations/annotation_models.dart';
import '../storage/app_database.dart';
import 'sync_repository.dart';

class SyncService {
  const SyncService({required AppDatabase db, required SyncRepository repo})
      : _db = db,
        _repo = repo;

  final AppDatabase _db;
  final SyncRepository _repo;

  Future<void> syncAll() => Future.wait([
        syncBookmarks(),
        syncNotes(),
        syncHighlights(),
      ]);

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<void> syncBookmarks() async {
    final pending = await _db.getPendingBookmarks();
    for (final b in pending) {
      try {
        switch (b.syncStatus) {
          case SyncStatus.pendingCreate:
            final remoteId = await _repo.createBookmark(b);
            await _db.updateAnnotationSync(
              'bookmarks', b.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (b.remoteId != null) {
              await _repo.updateBookmark(b.remoteId!, b);
              await _db.updateAnnotationSync(
                  'bookmarks', b.id!, SyncStatus.synced);
            }
          case SyncStatus.pendingDelete:
            if (b.remoteId != null) await _repo.deleteBookmark(b.remoteId!);
            await _db.deleteBookmark(b.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (_) {
        // Silent — will retry on next sync
      }
    }
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<void> syncNotes() async {
    final pending = await _db.getPendingNotes();
    for (final n in pending) {
      try {
        switch (n.syncStatus) {
          case SyncStatus.pendingCreate:
            final remoteId = await _repo.createNote(n);
            await _db.updateAnnotationSync(
              'notes', n.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (n.remoteId != null) {
              await _repo.updateNote(n.remoteId!, n);
              await _db.updateAnnotationSync(
                  'notes', n.id!, SyncStatus.synced);
            }
          case SyncStatus.pendingDelete:
            if (n.remoteId != null) await _repo.deleteNote(n.remoteId!);
            await _db.deleteNote(n.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (_) {}
    }
  }

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<void> syncHighlights() async {
    final pending = await _db.getPendingHighlights();
    for (final h in pending) {
      try {
        switch (h.syncStatus) {
          case SyncStatus.pendingCreate:
            final remoteId = await _repo.createHighlight(h);
            await _db.updateAnnotationSync(
              'highlights', h.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (h.remoteId != null) {
              await _repo.updateHighlight(h.remoteId!, h);
              await _db.updateAnnotationSync(
                  'highlights', h.id!, SyncStatus.synced);
            }
          case SyncStatus.pendingDelete:
            if (h.remoteId != null) await _repo.deleteHighlight(h.remoteId!);
            await _db.deleteHighlight(h.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (_) {}
    }
  }

  // ── Progress ───────────────────────────────────────────────────────────────

  Future<void> logReadingProgress({
    required String bookId,
    required int chapter,
  }) async {
    try {
      await _repo.logReadingProgress(bookId: bookId, chapter: chapter);
    } catch (_) {}
  }
}
