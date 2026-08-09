library;

/// Models representing the JSON export and import format for annotations.
///
/// This is pure Dart with zero Flutter dependencies.

enum BackupConflictPolicy {
  /// Keep existing annotations in database and skip incoming duplicates.
  skip,

  /// For notes, combine or merge note bodies. For bookmarks and highlights, keep existing.
  merge,

  /// Overwrite existing annotations with imported ones.
  replace,
}

class BackupBookmarkModel {
  const BackupBookmarkModel({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.createdAt,
    this.tags,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final int createdAt;
  final String? tags;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
        'createdAt': createdAt,
        if (tags != null) 'tags': tags,
      };

  factory BackupBookmarkModel.fromJson(Map<String, dynamic> json) {
    final bookId = json['bookId'];
    final chapter = json['chapter'];
    final verse = json['verse'];
    final createdAt = json['createdAt'];
    final tags = json['tags'] as String?;

    if (bookId is! String || bookId.isEmpty) {
      throw const FormatException('Invalid or missing "bookId" in bookmark.');
    }
    if (chapter is! int || chapter <= 0) {
      throw const FormatException('Invalid or missing "chapter" in bookmark.');
    }
    if (verse is! int || verse <= 0) {
      throw const FormatException('Invalid or missing "verse" in bookmark.');
    }
    if (createdAt is! int || createdAt < 0) {
      throw const FormatException('Invalid or missing "createdAt" in bookmark.');
    }

    return BackupBookmarkModel(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      createdAt: createdAt,
      tags: tags,
    );
  }
}

class BackupHighlightModel {
  const BackupHighlightModel({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.color,
    required this.createdAt,
    this.tags,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final int color;
  final int createdAt;
  final String? tags;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
        'color': color,
        'createdAt': createdAt,
        if (tags != null) 'tags': tags,
      };

  factory BackupHighlightModel.fromJson(Map<String, dynamic> json) {
    final bookId = json['bookId'];
    final chapter = json['chapter'];
    final verse = json['verse'];
    final color = json['color'];
    final createdAt = json['createdAt'];
    final tags = json['tags'] as String?;

    if (bookId is! String || bookId.isEmpty) {
      throw const FormatException('Invalid or missing "bookId" in highlight.');
    }
    if (chapter is! int || chapter <= 0) {
      throw const FormatException('Invalid or missing "chapter" in highlight.');
    }
    if (verse is! int || verse <= 0) {
      throw const FormatException('Invalid or missing "verse" in highlight.');
    }
    if (color is! int) {
      throw const FormatException('Invalid or missing "color" in highlight.');
    }
    if (createdAt is! int || createdAt < 0) {
      throw const FormatException('Invalid or missing "createdAt" in highlight.');
    }

    return BackupHighlightModel(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      color: color,
      createdAt: createdAt,
      tags: tags,
    );
  }
}

class BackupNoteModel {
  const BackupNoteModel({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
  });

  final String bookId;
  final int chapter;
  final int verse;
  final String body;
  final int createdAt;
  final int updatedAt;
  final String? tags;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
        'body': body,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        if (tags != null) 'tags': tags,
      };

  factory BackupNoteModel.fromJson(Map<String, dynamic> json) {
    final bookId = json['bookId'];
    final chapter = json['chapter'];
    final verse = json['verse'];
    final body = json['body'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final tags = json['tags'] as String?;

    if (bookId is! String || bookId.isEmpty) {
      throw const FormatException('Invalid or missing "bookId" in note.');
    }
    if (chapter is! int || chapter <= 0) {
      throw const FormatException('Invalid or missing "chapter" in note.');
    }
    if (verse is! int || verse <= 0) {
      throw const FormatException('Invalid or missing "verse" in note.');
    }
    if (body is! String) {
      throw const FormatException('Invalid or missing "body" in note.');
    }
    if (createdAt is! int || createdAt < 0) {
      throw const FormatException('Invalid or missing "createdAt" in note.');
    }
    if (updatedAt is! int || updatedAt < 0) {
      throw const FormatException('Invalid or missing "updatedAt" in note.');
    }

    return BackupNoteModel(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: tags,
    );
  }
}

class BackupCollectionItemModel {
  const BackupCollectionItemModel({
    required this.itemType,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  final String itemType;
  final String bookId;
  final int chapter;
  final int verse;

  Map<String, dynamic> toJson() => {
        'itemType': itemType,
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
      };

  factory BackupCollectionItemModel.fromJson(Map<String, dynamic> json) {
    return BackupCollectionItemModel(
      itemType: json['itemType'] as String,
      bookId: json['bookId'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
    );
  }
}

class BackupCollectionModel {
  const BackupCollectionModel({
    required this.name,
    this.color,
    this.icon,
    required this.items,
  });

  final String name;
  final int? color;
  final String? icon;
  final List<BackupCollectionItemModel> items;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory BackupCollectionModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final color = json['color'] as int?;
    final icon = json['icon'] as String?;
    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .map((e) => BackupCollectionItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return BackupCollectionModel(
      name: name,
      color: color,
      icon: icon,
      items: items,
    );
  }
}

class BackupPayload {
  const BackupPayload({
    required this.formatVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.bookmarks,
    required this.highlights,
    required this.notes,
    this.collections,
  });

  static const int currentFormatVersion = 1;

  final int formatVersion;
  final String exportedAt;
  final String appVersion;
  final List<BackupBookmarkModel> bookmarks;
  final List<BackupHighlightModel> highlights;
  final List<BackupNoteModel> notes;
  final List<BackupCollectionModel>? collections;

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'exportedAt': exportedAt,
        'appVersion': appVersion,
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        if (collections != null)
          'collections': collections!.map((c) => c.toJson()).toList(),
      };

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    final formatVersion = json['formatVersion'];
    if (formatVersion is! int) {
      throw const FormatException('Missing or invalid "formatVersion" in backup.');
    }
    if (formatVersion != currentFormatVersion) {
      throw FormatException(
        'Unsupported backup formatVersion: $formatVersion (expected $currentFormatVersion).',
      );
    }

    final exportedAt = json['exportedAt'] as String? ?? '';
    final appVersion = json['appVersion'] as String? ?? '1.0.0+1';

    final rawBookmarks = json['bookmarks'];
    if (rawBookmarks is! List) {
      throw const FormatException('Missing or invalid "bookmarks" list.');
    }
    final bookmarks = rawBookmarks
        .map((e) => BackupBookmarkModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawHighlights = json['highlights'];
    if (rawHighlights is! List) {
      throw const FormatException('Missing or invalid "highlights" list.');
    }
    final highlights = rawHighlights
        .map((e) => BackupHighlightModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawNotes = json['notes'];
    if (rawNotes is! List) {
      throw const FormatException('Missing or invalid "notes" list.');
    }
    final notes = rawNotes
        .map((e) => BackupNoteModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawCollections = json['collections'] as List?;
    final collections = rawCollections
        ?.map((e) => BackupCollectionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return BackupPayload(
      formatVersion: formatVersion,
      exportedAt: exportedAt,
      appVersion: appVersion,
      bookmarks: bookmarks,
      highlights: highlights,
      notes: notes,
      collections: collections,
    );
  }
}

class BackupPreview {
  const BackupPreview({
    required this.bookmarkCount,
    required this.highlightCount,
    required this.noteCount,
    required this.existingCount,
    required this.payload,
  });

  final int bookmarkCount;
  final int highlightCount;
  final int noteCount;
  final int existingCount;
  final BackupPayload payload;
}
