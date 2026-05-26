import 'package:flutter/foundation.dart';
import '../annotations/annotation_models.dart';
import '../api/api_client.dart';
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

  Future<void> pullAll() => Future.wait([
        _pullBookmarks(),
        _pullNotes(),
        _pullHighlights(),
      ]);

  Future<void> _pullBookmarks() async {
    try {
      final items = await _repo.fetchBookmarks();
      await _db.upsertServerBookmarks(items);
    } catch (_) {}
  }

  Future<void> _pullNotes() async {
    try {
      final items = await _repo.fetchNotes();
      await _db.upsertServerNotes(items);
    } catch (_) {}
  }

  Future<void> _pullHighlights() async {
    try {
      final items = await _repo.fetchHighlights();
      await _db.upsertServerHighlights(items);
    } catch (_) {}
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<void> syncBookmarks() async {
    final pending = await _db.getPendingBookmarks();
    debugPrint('[Sync] pending bookmarks: ${pending.length}');
    for (final b in pending) {
      debugPrint('[Sync] bookmark id=${b.id} status=${b.syncStatus.name} remoteId=${b.remoteId} bookId=${b.bookId}');
      try {
        switch (b.syncStatus) {
          case SyncStatus.pendingCreate:
            debugPrint('[Sync] creating bookmark bookId=${b.bookId} ch=${b.chapter} v=${b.verseStart}');
            final remoteId = await _repo.createBookmark(b);
            debugPrint('[Sync] bookmark created remoteId=$remoteId');
            await _db.updateAnnotationSync(
              'bookmarks', b.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (b.remoteId != null) {
              try {
                await _repo.updateBookmark(b.remoteId!, b);
                await _db.updateAnnotationSync('bookmarks', b.id!, SyncStatus.synced);
              } on ApiException catch (e) {
                if (e.statusCode == 404) {
                  final remoteId = await _repo.createBookmark(b);
                  await _db.updateAnnotationSync('bookmarks', b.id!, SyncStatus.synced, remoteId: remoteId);
                } else {
                  debugPrint('[Sync] bookmark update error ${e.statusCode}: $e');
                }
              }
            } else {
              debugPrint('[Sync] bookmark pendingUpdate but remoteId=null, treating as create');
              final remoteId = await _repo.createBookmark(b);
              await _db.updateAnnotationSync('bookmarks', b.id!, SyncStatus.synced, remoteId: remoteId);
            }
          case SyncStatus.pendingDelete:
            if (b.remoteId != null) {
              try { await _repo.deleteBookmark(b.remoteId!); } on ApiException catch (_) {}
            }
            await _db.deleteBookmark(b.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        final code = e is ApiException ? ' (HTTP ${e.statusCode})' : '';
        debugPrint('[Sync] bookmark error$code (${e.runtimeType}): $e');
      }
    }
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<void> syncNotes() async {
    final pending = await _db.getPendingNotes();
    debugPrint('[Sync] pending notes: ${pending.length}');
    for (final n in pending) {
      debugPrint('[Sync] note id=${n.id} status=${n.syncStatus.name} remoteId=${n.remoteId} bookId=${n.bookId}');
      try {
        switch (n.syncStatus) {
          case SyncStatus.pendingCreate:
            debugPrint('[Sync] creating note bookId=${n.bookId} ch=${n.chapter} v=${n.verseStart}');
            final remoteId = await _repo.createNote(n);
            debugPrint('[Sync] note created remoteId=$remoteId');
            await _db.updateAnnotationSync(
              'notes', n.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (n.remoteId != null) {
              try {
                await _repo.updateNote(n.remoteId!, n);
                await _db.updateAnnotationSync('notes', n.id!, SyncStatus.synced);
              } on ApiException catch (e) {
                if (e.statusCode == 404) {
                  debugPrint('[Sync] note 404 on update, creating fresh for ${n.bookId} ch=${n.chapter} v=${n.verseStart}');
                  final remoteId = await _repo.createNote(n);
                  await _db.updateAnnotationSync('notes', n.id!, SyncStatus.synced, remoteId: remoteId);
                  debugPrint('[Sync] note re-created remoteId=$remoteId');
                } else {
                  debugPrint('[Sync] note update error ${e.statusCode}: $e');
                }
              }
            } else {
              debugPrint('[Sync] note pendingUpdate but remoteId=null, treating as create');
              final remoteId = await _repo.createNote(n);
              await _db.updateAnnotationSync('notes', n.id!, SyncStatus.synced, remoteId: remoteId);
              debugPrint('[Sync] note created remoteId=$remoteId');
            }
          case SyncStatus.pendingDelete:
            if (n.remoteId != null) {
              try { await _repo.deleteNote(n.remoteId!); } on ApiException catch (_) {}
            }
            await _db.deleteNote(n.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        final code = e is ApiException ? ' (HTTP ${e.statusCode})' : '';
        debugPrint('[Sync] note error$code (${e.runtimeType}): $e');
      }
    }
  }

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<void> syncHighlights() async {
    final pending = await _db.getPendingHighlights();
    debugPrint('[Sync] pending highlights: ${pending.length}');
    for (final h in pending) {
      debugPrint('[Sync] highlight id=${h.id} status=${h.syncStatus.name} remoteId=${h.remoteId} bookId=${h.bookId}');
      try {
        switch (h.syncStatus) {
          case SyncStatus.pendingCreate:
            debugPrint('[Sync] creating highlight bookId=${h.bookId} ch=${h.chapter} v=${h.verseStart}');
            final remoteId = await _repo.createHighlight(h);
            debugPrint('[Sync] highlight created remoteId=$remoteId');
            await _db.updateAnnotationSync(
              'highlights', h.id!, SyncStatus.synced,
              remoteId: remoteId,
            );
          case SyncStatus.pendingUpdate:
            if (h.remoteId != null) {
              try {
                await _repo.updateHighlight(h.remoteId!, h);
                await _db.updateAnnotationSync('highlights', h.id!, SyncStatus.synced);
              } on ApiException catch (e) {
                if (e.statusCode == 404) {
                  final remoteId = await _repo.createHighlight(h);
                  await _db.updateAnnotationSync('highlights', h.id!, SyncStatus.synced, remoteId: remoteId);
                } else {
                  debugPrint('[Sync] highlight update error ${e.statusCode}: $e');
                }
              }
            } else {
              debugPrint('[Sync] highlight pendingUpdate but remoteId=null, treating as create');
              final remoteId = await _repo.createHighlight(h);
              await _db.updateAnnotationSync('highlights', h.id!, SyncStatus.synced, remoteId: remoteId);
            }
          case SyncStatus.pendingDelete:
            if (h.remoteId != null) {
              try { await _repo.deleteHighlight(h.remoteId!); } on ApiException catch (_) {}
            }
            await _db.deleteHighlight(h.id!);
          case SyncStatus.synced:
            break;
        }
      } catch (e) {
        final code = e is ApiException ? ' (HTTP ${e.statusCode})' : '';
        debugPrint('[Sync] highlight error$code (${e.runtimeType}): $e');
      }
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
