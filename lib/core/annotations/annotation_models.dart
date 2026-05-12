import 'package:flutter/material.dart';

enum SyncStatus { pendingCreate, pendingUpdate, pendingDelete, synced }

const highlightPalette = <Color>[
  Color(0xFFFFEB3B), // yellow
  Color(0xFF80CBC4), // teal
  Color(0xFF90CAF9), // sky blue
  Color(0xFFEF9A9A), // pink-red
  Color(0xFFCE93D8), // purple
];

// ── Bookmark ──────────────────────────────────────────────────────────────────

class Bookmark {
  const Bookmark({
    this.id,
    required this.bookId,
    required this.bookNumber,
    required this.chapter,
    required this.verseStart,
    this.verseCount = 1,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.remoteId,
  });

  final int? id;
  final String bookId;
  final int bookNumber;
  final int chapter;
  final int verseStart;
  final int verseCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? remoteId;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'book_id': bookId,
        'book_number': bookNumber,
        'chapter': chapter,
        'verse_start': verseStart,
        'verse_count': verseCount,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'sync_status': syncStatus.name,
        'remote_id': remoteId,
      };

  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(
        id: m['id'] as int,
        bookId: m['book_id'] as String,
        bookNumber: m['book_number'] as int,
        chapter: m['chapter'] as int,
        verseStart: m['verse_start'] as int,
        verseCount: m['verse_count'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        syncStatus: SyncStatus.values.byName(m['sync_status'] as String),
        remoteId: m['remote_id'] as String?,
      );
}

// ── Highlight ─────────────────────────────────────────────────────────────────

class Highlight {
  const Highlight({
    this.id,
    required this.bookId,
    required this.bookNumber,
    required this.chapter,
    required this.verseStart,
    this.verseCount = 1,
    required this.color,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.remoteId,
  });

  final int? id;
  final String bookId;
  final int bookNumber;
  final int chapter;
  final int verseStart;
  final int verseCount;
  final Color color;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? remoteId;

  Highlight copyWith({
    Color? color,
    String? note,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) =>
      Highlight(
        id: id,
        bookId: bookId,
        bookNumber: bookNumber,
        chapter: chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        color: color ?? this.color,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteId: remoteId,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'book_id': bookId,
        'book_number': bookNumber,
        'chapter': chapter,
        'verse_start': verseStart,
        'verse_count': verseCount,
        'color': color.toARGB32(),
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'sync_status': syncStatus.name,
        'remote_id': remoteId,
      };

  factory Highlight.fromMap(Map<String, dynamic> m) {
    final argb = m['color'] as int;
    return Highlight(
      id: m['id'] as int,
      bookId: m['book_id'] as String,
      bookNumber: m['book_number'] as int,
      chapter: m['chapter'] as int,
      verseStart: m['verse_start'] as int,
      verseCount: m['verse_count'] as int,
      color: Color.fromARGB(
        (argb >> 24) & 0xFF,
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF,
      ),
      note: m['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      syncStatus: SyncStatus.values.byName(m['sync_status'] as String),
      remoteId: m['remote_id'] as String?,
    );
  }
}

// ── Note ──────────────────────────────────────────────────────────────────────

class Note {
  const Note({
    this.id,
    required this.bookId,
    required this.bookNumber,
    required this.chapter,
    required this.verseStart,
    this.verseCount = 1,
    required this.content,
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.remoteId,
  });

  final int? id;
  final String bookId;
  final int bookNumber;
  final int chapter;
  final int verseStart;
  final int verseCount;
  final String content;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? remoteId;

  Note copyWith({
    String? content,
    bool? isPrivate,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) =>
      Note(
        id: id,
        bookId: bookId,
        bookNumber: bookNumber,
        chapter: chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        content: content ?? this.content,
        isPrivate: isPrivate ?? this.isPrivate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteId: remoteId,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'book_id': bookId,
        'book_number': bookNumber,
        'chapter': chapter,
        'verse_start': verseStart,
        'verse_count': verseCount,
        'content': content,
        'is_private': isPrivate ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'sync_status': syncStatus.name,
        'remote_id': remoteId,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as int,
        bookId: m['book_id'] as String,
        bookNumber: m['book_number'] as int,
        chapter: m['chapter'] as int,
        verseStart: m['verse_start'] as int,
        verseCount: m['verse_count'] as int,
        content: m['content'] as String,
        isPrivate: (m['is_private'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        syncStatus: SyncStatus.values.byName(m['sync_status'] as String),
        remoteId: m['remote_id'] as String?,
      );
}

// ── Aggregated chapter view ───────────────────────────────────────────────────

class ChapterAnnotations {
  const ChapterAnnotations({
    this.bookmarks = const [],
    this.highlights = const [],
    this.notes = const [],
  });

  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final List<Note> notes;

  static const empty = ChapterAnnotations();

  bool isBookmarked(int verseStart) =>
      bookmarks.any((b) => b.verseStart == verseStart);

  Color? highlightColor(int verseStart) =>
      highlights.where((h) => h.verseStart == verseStart).firstOrNull?.color;

  Note? noteFor(int verseStart) =>
      notes.where((n) => n.verseStart == verseStart).firstOrNull;
}
