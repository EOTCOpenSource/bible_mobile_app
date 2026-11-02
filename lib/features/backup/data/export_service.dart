import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_database.dart';
import '../../books/data/models/book_identity.dart';
import '../../books/data/repositories/bible_repository.dart';
import 'backup_models.dart';

class ExportService {
  ExportService({
    required AppDatabase db,
    required BibleRepository bibleRepository,
  })  : _db = db,
        _bibleRepository = bibleRepository;

  final AppDatabase _db;
  final BibleRepository _bibleRepository;

  /// Generates a single JSON backup payload and writes it to [targetFile].
  ///
  /// If an error occurs during generation or file writing, the partial file is cleaned up.
  Future<File> exportToJson(File targetFile, {String appVersion = '1.0.0+1'}) async {
    try {
      final bookmarks = await _db.getAllBookmarks();
      final highlights = await _db.getAllHighlights();
      final notes = await _db.getAllNotes();

      final backupBookmarks = bookmarks.map((b) {
        return BackupBookmarkModel(
          bookId: apiBookIdFromUsfm(b.bookId),
          chapter: b.chapter,
          verse: b.verseStart,
          createdAt: b.createdAt.millisecondsSinceEpoch,
          tags: b.tags,
        );
      }).toList();

      final backupHighlights = highlights.map((h) {
        return BackupHighlightModel(
          bookId: apiBookIdFromUsfm(h.bookId),
          chapter: h.chapter,
          verse: h.verseStart,
          color: h.color.toARGB32(),
          createdAt: h.createdAt.millisecondsSinceEpoch,
          tags: h.tags,
        );
      }).toList();

      final backupNotes = notes.map((n) {
        return BackupNoteModel(
          bookId: apiBookIdFromUsfm(n.bookId),
          chapter: n.chapter,
          verse: n.verseStart,
          body: n.content,
          createdAt: n.createdAt.millisecondsSinceEpoch,
          updatedAt: n.updatedAt.millisecondsSinceEpoch,
          tags: n.tags,
        );
      }).toList();

      final collections = await _db.listCollections();
      final backupCollections = <BackupCollectionModel>[];
      final bMap = {for (final b in bookmarks) b.id: b};
      final hMap = {for (final h in highlights) h.id: h};
      final nMap = {for (final n in notes) n.id: n};

      for (final col in collections) {
        if (col.id == null) continue;
        final rawItems = await _db.listItemsInCollection(col.id!);
        final items = <BackupCollectionItemModel>[];
        for (final item in rawItems) {
          final type = item['item_type'] as String?;
          final itemId = item['item_id'] as int?;
          if (type == null || itemId == null) continue;
          if (type == 'bookmark' && bMap.containsKey(itemId)) {
            final b = bMap[itemId]!;
            items.add(BackupCollectionItemModel(
              itemType: type,
              bookId: apiBookIdFromUsfm(b.bookId),
              chapter: b.chapter,
              verse: b.verseStart,
            ));
          } else if (type == 'highlight' && hMap.containsKey(itemId)) {
            final h = hMap[itemId]!;
            items.add(BackupCollectionItemModel(
              itemType: type,
              bookId: apiBookIdFromUsfm(h.bookId),
              chapter: h.chapter,
              verse: h.verseStart,
            ));
          } else if (type == 'note' && nMap.containsKey(itemId)) {
            final n = nMap[itemId]!;
            items.add(BackupCollectionItemModel(
              itemType: type,
              bookId: apiBookIdFromUsfm(n.bookId),
              chapter: n.chapter,
              verse: n.verseStart,
            ));
          }
        }
        backupCollections.add(BackupCollectionModel(
          name: col.name,
          color: col.color?.toARGB32(),
          icon: col.icon,
          items: items,
        ));
      }

      final payload = BackupPayload(
        formatVersion: BackupPayload.currentFormatVersion,
        exportedAt: DateTime.now().toUtc().toIso8601String(),
        appVersion: appVersion,
        bookmarks: backupBookmarks,
        highlights: backupHighlights,
        notes: backupNotes,
        collections: backupCollections,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(payload.toJson());

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await targetFile.writeAsString(jsonString, flush: true);
      return targetFile;
    } catch (e) {
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Generates a human-readable Markdown backup file grouped by book -> chapter -> verse.
  ///
  /// Verses are resolved through [BibleRepository] so the exported document stands alone.
  Future<File> exportToMarkdown(File targetFile) async {
    try {
      final bookmarks = await _db.getAllBookmarks();
      final highlights = await _db.getAllHighlights();
      final notes = await _db.getAllNotes();

      // Collect all (bookId, chapter, verseStart) tuples
      final verseKeys = <String, Set<_VerseKey>>{};

      void addKey(String usfmId, int chapter, int verse) {
        verseKeys.putIfAbsent(usfmId, () => {}).add(_VerseKey(chapter, verse));
      }

      for (final b in bookmarks) {
        addKey(b.bookId, b.chapter, b.verseStart);
      }
      for (final h in highlights) {
        addKey(h.bookId, h.chapter, h.verseStart);
      }
      for (final n in notes) {
        addKey(n.bookId, n.chapter, n.verseStart);
      }

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final sink = targetFile.openWrite();
      sink.writeln('# የኢኦተቤ ማስታወሻዎች እና ዕልባቶች (Annotations Backup)');
      sink.writeln();
      sink.writeln('> *ማስታወሻ፦ ይህ ፋይል ለንባብ ብቻ የተዘጋጀ ነው (This file is export-only and cannot be re-imported).*');
      sink.writeln();

      final sortedBookIds = verseKeys.keys.toList();
      // Sort books by book index entry order if available
      final index = await _bibleRepository.loadIndex();
      final orderMap = {for (var i = 0; i < index.length; i++) index[i].id: i};
      sortedBookIds.sort((a, b) => (orderMap[a] ?? 999).compareTo(orderMap[b] ?? 999));

      for (final bookId in sortedBookIds) {
        final bookEntry = await _bibleRepository.bookById(bookId);
        final bookTitleAm = bookEntry?.bookNameAm ?? bookId;
        final bookTitleEn = bookEntry?.bookNameEn ?? bookId;

        sink.writeln('## $bookTitleAm ($bookTitleEn)');
        sink.writeln();

        final keys = verseKeys[bookId]!.toList()
          ..sort((a, b) {
            final c = a.chapter.compareTo(b.chapter);
            return c != 0 ? c : a.verse.compareTo(b.verse);
          });

        int? currentChapter;
        for (final k in keys) {
          if (currentChapter != k.chapter) {
            currentChapter = k.chapter;
            sink.writeln('### ምዕራፍ $currentChapter');
            sink.writeln();
          }

          final verseText = await _bibleRepository.verseText(bookId, k.chapter, k.verse);
          sink.writeln('#### $currentChapter:${k.verse}');

          if (verseText != null && verseText.trim().isNotEmpty) {
            sink.writeln('> ${verseText.trim()}');
            sink.writeln();
          }

          // Check if bookmarked
          final isBookmarked = bookmarks.any(
            (b) => b.bookId == bookId && b.chapter == k.chapter && b.verseStart == k.verse,
          );
          if (isBookmarked) {
            sink.writeln('- 📌 **ዕልባት (Bookmark)**');
          }

          // Check if highlighted
          final matchingHighlights = highlights.where(
            (h) => h.bookId == bookId && h.chapter == k.chapter && h.verseStart == k.verse,
          );
          for (final h in matchingHighlights) {
            final colorHex = '#${h.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
            sink.writeln('- 🖍️ **ጎልቶ የተወከለ (Highlight):** `$colorHex`');
          }

          // Check for notes
          final matchingNotes = notes.where(
            (n) => n.bookId == bookId && n.chapter == k.chapter && n.verseStart == k.verse,
          );
          for (final n in matchingNotes) {
            sink.writeln();
            sink.writeln('**ማስታወሻ (Note):**');
            sink.writeln(n.content.trim());
            sink.writeln();
          }

          sink.writeln();
        }
      }

      await sink.flush();
      await sink.close();
      return targetFile;
    } catch (e) {
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}

class _VerseKey {
  const _VerseKey(this.chapter, this.verse);
  final int chapter;
  final int verse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _VerseKey &&
          runtimeType == other.runtimeType &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => chapter.hashCode ^ verse.hashCode;
}
