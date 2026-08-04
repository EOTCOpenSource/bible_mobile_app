import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/annotations/annotation_models.dart';
import '../../../core/storage/app_database.dart';
import '../../books/data/models/book_identity.dart';
import '../../books/data/repositories/bible_repository.dart';
import 'backup_models.dart';

class ImportService {
  ImportService({
    required AppDatabase db,
    required BibleRepository bibleRepository,
  })  : _db = db,
        _bibleRepository = bibleRepository;

  final AppDatabase _db;
  final BibleRepository _bibleRepository;

  /// Parses the JSON [content], validates [formatVersion] and field types,
  /// and calculates conflict counts against the local database.
  Future<BackupPreview> parseAndPreview(String content) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (e) {
      throw FormatException('Import failed — file may be corrupted: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Import failed — file must contain a valid JSON object.');
    }

    final payload = BackupPayload.fromJson(decoded);

    // Collect tuples to query database for conflict detection
    final bTuples = payload.bookmarks.map((b) {
      final usfm = usfmFromAnyBookId(b.bookId);
      return (usfmBookId: usfm, chapter: b.chapter, verse: b.verse);
    }).toList();

    final hTuples = payload.highlights.map((h) {
      final usfm = usfmFromAnyBookId(h.bookId);
      return (usfmBookId: usfm, chapter: h.chapter, verse: h.verse);
    }).toList();

    final nTuples = payload.notes.map((n) {
      final usfm = usfmFromAnyBookId(n.bookId);
      return (usfmBookId: usfm, chapter: n.chapter, verse: n.verse);
    }).toList();

    final existingCount = await _db.countExistingConflicts(
      bookmarks: bTuples,
      highlights: hTuples,
      notes: nTuples,
    );

    return BackupPreview(
      bookmarkCount: payload.bookmarks.length,
      highlightCount: payload.highlights.length,
      noteCount: payload.notes.length,
      existingCount: existingCount,
      payload: payload,
    );
  }

  /// Executes the import transaction using the specified [conflictPolicy].
  ///
  /// Every imported row is assigned `sync_status = 'pendingCreate'` so it will
  /// propagate to the backend on the next sync.
  Future<void> executeImport({
    required BackupPayload payload,
    required BackupConflictPolicy conflictPolicy,
  }) async {
    final index = await _bibleRepository.loadIndex();
    final bookNumberMap = {for (final e in index) e.id: e.bookNumber};

    int resolveBookNumber(String usfmId) {
      return bookNumberMap[usfmId] ?? 1;
    }

    final bookmarks = payload.bookmarks.map((b) {
      final usfm = usfmFromAnyBookId(b.bookId);
      final bookNo = resolveBookNumber(usfm);
      return Bookmark(
        bookId: usfm,
        bookNumber: bookNo,
        chapter: b.chapter,
        verseStart: b.verse,
        verseCount: 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(b.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(b.createdAt),
        syncStatus: SyncStatus.pendingCreate,
        remoteId: null,
      );
    }).toList();

    final highlights = payload.highlights.map((h) {
      final usfm = usfmFromAnyBookId(h.bookId);
      final bookNo = resolveBookNumber(usfm);
      final argb = h.color;
      return Highlight(
        bookId: usfm,
        bookNumber: bookNo,
        chapter: h.chapter,
        verseStart: h.verse,
        verseCount: 1,
        color: Color.fromARGB(
          (argb >> 24) & 0xFF,
          (argb >> 16) & 0xFF,
          (argb >> 8) & 0xFF,
          argb & 0xFF,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(h.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(h.createdAt),
        syncStatus: SyncStatus.pendingCreate,
        remoteId: null,
      );
    }).toList();

    final notes = payload.notes.map((n) {
      final usfm = usfmFromAnyBookId(n.bookId);
      final bookNo = resolveBookNumber(usfm);
      return Note(
        bookId: usfm,
        bookNumber: bookNo,
        chapter: n.chapter,
        verseStart: n.verse,
        verseCount: 1,
        content: n.body,
        isPrivate: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(n.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(n.updatedAt),
        syncStatus: SyncStatus.pendingCreate,
        remoteId: null,
      );
    }).toList();

    await _db.importAnnotations(
      bookmarks: bookmarks,
      highlights: highlights,
      notes: notes,
      conflictPolicy: conflictPolicy,
    );
  }
}
