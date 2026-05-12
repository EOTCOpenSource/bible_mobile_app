import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/annotations/annotation_models.dart';
import '../../../core/storage/app_database.dart';

// ── DB singleton ──────────────────────────────────────────────────────────────

final annotationDbProvider = Provider<AppDatabase>((_) => AppDatabase());

// ── Chapter key ───────────────────────────────────────────────────────────────

typedef ChapterKey = ({String bookId, int chapter});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChapterAnnotationsNotifier
    extends StateNotifier<AsyncValue<ChapterAnnotations>> {
  ChapterAnnotationsNotifier(this._db, this._key)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final AppDatabase _db;
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
  }) async {
    final annotations = state.value;
    if (annotations == null) return;
    final existing =
        annotations.bookmarks.where((b) => b.verseStart == verseStart).firstOrNull;
    if (existing != null) {
      await _db.deleteBookmark(existing.id!);
    } else {
      final now = DateTime.now();
      await _db.insertBookmark(Bookmark(
        bookId: _key.bookId,
        bookNumber: bookNumber,
        chapter: _key.chapter,
        verseStart: verseStart,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
  }

  Future<void> setHighlight({
    required int verseStart,
    required int bookNumber,
    required Color color,
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
        color: color,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
  }

  Future<void> removeHighlight(int verseStart) async {
    final existing = state.value?.highlights
        .where((h) => h.verseStart == verseStart)
        .firstOrNull;
    if (existing != null) {
      await _db.deleteHighlight(existing.id!);
      await _load();
    }
  }

  Future<void> saveNote({
    required int verseStart,
    required int bookNumber,
    required String content,
  }) async {
    final annotations = state.value;
    if (annotations == null) return;
    final existing =
        annotations.notes.where((n) => n.verseStart == verseStart).firstOrNull;
    final now = DateTime.now();
    if (existing != null) {
      if (content.trim().isEmpty) {
        await _db.deleteNote(existing.id!);
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
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      ));
    }
    await _load();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final chapterAnnotationsProvider = StateNotifierProvider.family<
    ChapterAnnotationsNotifier,
    AsyncValue<ChapterAnnotations>,
    ChapterKey>(
  (ref, key) => ChapterAnnotationsNotifier(ref.watch(annotationDbProvider), key),
);
