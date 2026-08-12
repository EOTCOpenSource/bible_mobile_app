import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/annotations/annotation_models.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/app_database_provider.dart';
import '../../../core/sync/sync_repository.dart';
import '../../../core/sync/sync_service.dart';

export '../../../core/storage/app_database_provider.dart'
    show appDatabaseProvider, annotationDbProvider;

// ── Chapter key ───────────────────────────────────────────────────────────────

typedef ChapterKey = ({String bookId, int chapter});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChapterAnnotationsNotifier
    extends StateNotifier<AsyncValue<ChapterAnnotations>> {
  ChapterAnnotationsNotifier(this._db, this._ref, this._key)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final AppDatabase _db;
  final Ref _ref;
  final ChapterKey _key;

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _db.getBookmarks(_key.bookId, _key.chapter),
        _db.getHighlights(_key.bookId, _key.chapter),
        _db.getNotes(_key.bookId, _key.chapter),
      ]);
      if (mounted) {
        state = AsyncValue.data(ChapterAnnotations(
          bookmarks: results[0] as List<Bookmark>,
          highlights: results[1] as List<Highlight>,
          notes: results[2] as List<Note>,
        ));
      }
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggleBookmark({
    required int verseStart,
    required int bookNumber,
    int verseCount = 1,
  }) async {
    final annotations = state.value;
    if (annotations == null) return;
    final existing =
        annotations.bookmarks.where((b) => b.verseStart == verseStart).firstOrNull;
    if (existing != null) {
      await _db.softDeleteBookmark(
          existing.id!, hasRemoteId: existing.remoteId != null);
    } else {
      final now = DateTime.now();
      await _db.insertBookmark(Bookmark(
        bookId: _key.bookId,
        bookNumber: bookNumber,
        chapter: _key.chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
    _triggerSync();
  }

  Future<void> setHighlight({
    required int verseStart,
    required int bookNumber,
    required Color color,
    int verseCount = 1,
  }) async {
    final annotations = state.value;
    if (annotations == null) return;
    final existing =
        annotations.highlights.where((h) => h.verseStart == verseStart).firstOrNull;
    final now = DateTime.now();
    if (existing != null) {
      await _db.updateHighlight(existing.copyWith(
        color: color,
        updatedAt: now,
        syncStatus: existing.syncStatus == SyncStatus.synced
            ? SyncStatus.pendingUpdate
            : existing.syncStatus,
      ));
    } else {
      await _db.insertHighlight(Highlight(
        bookId: _key.bookId,
        bookNumber: bookNumber,
        chapter: _key.chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        color: color,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
    _triggerSync();
  }

  Future<void> removeHighlight(int verseStart) async {
    final existing = state.value?.highlights
        .where((h) => h.verseStart == verseStart)
        .firstOrNull;
    if (existing != null) {
      await _db.softDeleteHighlight(
          existing.id!, hasRemoteId: existing.remoteId != null);
      await _load();
      _triggerSync();
    }
  }

  Future<void> saveNote({
    required int verseStart,
    required int bookNumber,
    required String content,
    int verseCount = 1,
  }) async {
    final annotations = state.value;
    if (annotations == null) return;
    final existing =
        annotations.notes.where((n) => n.verseStart == verseStart).firstOrNull;
    final now = DateTime.now();
    if (existing != null) {
      if (content.trim().isEmpty) {
        await _db.softDeleteNote(
            existing.id!, hasRemoteId: existing.remoteId != null);
      } else {
        await _db.updateNote(existing.copyWith(
          content: content.trim(),
          updatedAt: now,
          syncStatus: existing.syncStatus == SyncStatus.synced
              ? SyncStatus.pendingUpdate
              : existing.syncStatus,
        ));
      }
    } else if (content.trim().isNotEmpty) {
      await _db.insertNote(Note(
        bookId: _key.bookId,
        bookNumber: bookNumber,
        chapter: _key.chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
    _triggerSync();
  }

  void _triggerSync() {
    final token = _ref.read(authStateProvider).token;
    if (token == null) return;
    SyncService(
      db: _db,
      repo: SyncRepository(_ref.read(apiClientProvider), token),
    ).syncAll();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final chapterAnnotationsProvider = StateNotifierProvider.family<
    ChapterAnnotationsNotifier,
    AsyncValue<ChapterAnnotations>,
    ChapterKey>(
  (ref, key) =>
      ChapterAnnotationsNotifier(ref.watch(annotationDbProvider), ref, key),
);

// ── Collections Providers ────────────────────────────────────────────────

final collectionsProvider = FutureProvider<List<Collection>>((ref) async {
  final db = ref.watch(annotationDbProvider);
  return db.listCollections();
});

final selectedCollectionIdProvider = StateProvider<int?>((ref) => null);

class CollectionsNotifier extends StateNotifier<AsyncValue<List<Collection>>> {
  CollectionsNotifier(this._db) : super(const AsyncValue.loading()) {
    refresh();
  }

  final AppDatabase _db;

  Future<void> refresh() async {
    try {
      final list = await _db.listCollections();
      if (mounted) state = AsyncValue.data(list);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<int> createCollection(String name, {Color? color, String? icon}) async {
    final id = await _db.createCollection(
      name,
      color: color?.toARGB32(),
      icon: icon,
    );
    await refresh();
    return id;
  }

  Future<void> updateCollection(Collection c) async {
    await _db.updateCollection(c);
    await refresh();
  }

  Future<void> deleteCollection(int id) async {
    await _db.deleteCollection(id);
    await refresh();
  }

  Future<void> reorderCollections(List<Collection> list) async {
    await _db.reorderCollections(list);
    await refresh();
  }
}

final collectionsNotifierProvider = StateNotifierProvider<
    CollectionsNotifier,
    AsyncValue<List<Collection>>>((ref) {
  return CollectionsNotifier(ref.watch(annotationDbProvider));
});
