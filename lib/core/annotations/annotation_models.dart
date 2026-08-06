import 'package:flutter/material.dart';

enum SyncStatus { pendingCreate, pendingUpdate, pendingDelete, synced }

const highlightPalette = <Color>[
  Color(0xFFFFE062), // yellow
  Color(0xFF3BAD49), // green
  Color(0xFFFF4B26), // pink
  Color(0xFF5778C5), // blue
  Color(0xFFB61F21), // red
  Color(0xFF704A6A), // purple
];

// ARCHITECTURAL DECISION (Issue #25):
// Tags are stored as a comma-separated normalized string in the `tags` column of each
// annotation table (bookmarks, highlights, notes) rather than using a full join table.
// This lightweight implementation satisfies scaling needs while avoiding migration
// costs and complex multi-table joins. If a future contributor prefers a formal join table,
// this decision can be revisited.

/// Normalizes a comma-separated tag string by:
/// 1. Trimming each tag
/// 2. Collapsing internal whitespace
/// 3. Case-folding (converting to lowercase for English; Amharic is unaffected)
/// 4. Deduplicating while preserving order
///
/// Example: `" ጾም , prayer ,  ጾም "` -> `"ጾም,prayer"`
String? normalizeTags(String? rawTags) {
  if (rawTags == null) return null;
  final split = rawTags.split(',');
  final processed = <String>[];
  final seen = <String>{};
  for (final tag in split) {
    final trimmed = tag.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (trimmed.isNotEmpty && seen.add(trimmed)) {
      processed.add(trimmed);
    }
  }
  if (processed.isEmpty) return null;
  return processed.join(',');
}

// ── Collection ────────────────────────────────────────────────────────────────

class Collection {
  const Collection({
    this.id,
    required this.name,
    this.color,
    this.icon,
    this.sortOrder = 0,
    required this.createdAt,
    this.remoteId,
    this.syncStatus = SyncStatus.pendingCreate,
  });

  final int? id;
  final String name;
  final Color? color;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  final String? remoteId;
  final SyncStatus syncStatus;

  Collection copyWith({
    int? id,
    String? name,
    Color? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    String? remoteId,
    SyncStatus? syncStatus,
  }) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        remoteId: remoteId ?? this.remoteId,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'color': color?.toARGB32(),
        'icon': icon,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
        'remote_id': remoteId,
        'sync_status': syncStatus.name,
      };

  factory Collection.fromMap(Map<String, dynamic> m) {
    final argb = m['color'] as int?;
    return Collection(
      id: m['id'] as int?,
      name: m['name'] as String,
      color: argb != null ? Color(argb) : null,
      icon: m['icon'] as String?,
      sortOrder: m['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      remoteId: m['remote_id'] as String?,
      syncStatus: SyncStatus.values.byName(
        m['sync_status'] as String? ?? SyncStatus.pendingCreate.name,
      ),
    );
  }
}

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
    this.tags,
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
  final String? tags;

  Bookmark copyWith({
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? tags,
  }) =>
      Bookmark(
        id: id,
        bookId: bookId,
        bookNumber: bookNumber,
        chapter: chapter,
        verseStart: verseStart,
        verseCount: verseCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        remoteId: remoteId,
        tags: tags ?? this.tags,
      );

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
        'tags': tags,
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
        tags: m['tags'] as String?,
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
    this.tags,
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
  final String? tags;

  Highlight copyWith({
    Color? color,
    String? note,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? tags,
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
        tags: tags ?? this.tags,
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
        'tags': tags,
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
      tags: m['tags'] as String?,
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
    this.tags,
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
  final String? tags;

  Note copyWith({
    String? content,
    bool? isPrivate,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? tags,
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
        tags: tags ?? this.tags,
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
        'tags': tags,
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
        tags: m['tags'] as String?,
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

  bool isBookmarked(int verseNum) => bookmarks.any(
      (b) => verseNum >= b.verseStart && verseNum < b.verseStart + b.verseCount);

  Color? highlightColor(int verseNum) => highlights
      .where((h) =>
          verseNum >= h.verseStart && verseNum < h.verseStart + h.verseCount)
      .firstOrNull
      ?.color;

  Note? noteFor(int verseNum) => notes
      .where((n) =>
          verseNum >= n.verseStart && verseNum < n.verseStart + n.verseCount)
      .firstOrNull;
}
