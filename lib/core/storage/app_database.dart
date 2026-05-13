import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../annotations/annotation_models.dart';

class AppDatabase {
  static const _dbName = 'bibleapp.db';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createReadingTables(db);
    }
  }

  /// Reading progress + streak (v2). Used by [onCreate] and migration.
  Future<void> _createReadingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_position (
        id           INTEGER PRIMARY KEY CHECK (id = 1),
        book_id      TEXT    NOT NULL,
        chapter      INTEGER NOT NULL,
        verse        INTEGER,
        updated_at   INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapter_read (
        book_id         TEXT    NOT NULL,
        chapter         INTEGER NOT NULL,
        first_read_at   INTEGER NOT NULL,
        PRIMARY KEY (book_id, chapter)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_streak (
        id                    INTEGER PRIMARY KEY CHECK (id = 1),
        last_qualified_date   TEXT,
        current_streak        INTEGER NOT NULL DEFAULT 0,
        current_streak_start  TEXT,
        longest_streak        INTEGER NOT NULL DEFAULT 0,
        longest_streak_start  TEXT,
        longest_streak_end    TEXT
      )
    ''');
    await db.insert(
      'reading_streak',
      {
        'id': 1,
        'last_qualified_date': null,
        'current_streak': 0,
        'current_streak_start': null,
        'longest_streak': 0,
        'longest_streak_start': null,
        'longest_streak_end': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id      TEXT    NOT NULL,
        book_number  INTEGER NOT NULL,
        chapter      INTEGER NOT NULL,
        verse_start  INTEGER NOT NULL,
        verse_count  INTEGER NOT NULL DEFAULT 1,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        sync_status  TEXT    NOT NULL DEFAULT 'pendingCreate',
        remote_id    TEXT,
        UNIQUE(book_id, chapter, verse_start)
      )
    ''');
    await db.execute('''
      CREATE TABLE highlights (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id      TEXT    NOT NULL,
        book_number  INTEGER NOT NULL,
        chapter      INTEGER NOT NULL,
        verse_start  INTEGER NOT NULL,
        verse_count  INTEGER NOT NULL DEFAULT 1,
        color        INTEGER NOT NULL,
        note         TEXT,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        sync_status  TEXT    NOT NULL DEFAULT 'pendingCreate',
        remote_id    TEXT,
        UNIQUE(book_id, chapter, verse_start)
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id      TEXT    NOT NULL,
        book_number  INTEGER NOT NULL,
        chapter      INTEGER NOT NULL,
        verse_start  INTEGER NOT NULL,
        verse_count  INTEGER NOT NULL DEFAULT 1,
        content      TEXT    NOT NULL,
        is_private   INTEGER NOT NULL DEFAULT 1,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        sync_status  TEXT    NOT NULL DEFAULT 'pendingCreate',
        remote_id    TEXT,
        UNIQUE(book_id, chapter, verse_start)
      )
    ''');
    await _createReadingTables(db);
  }

  // ── Reading position / progress / streak ───────────────────────────────────

  Future<Map<String, Object?>?> getReadingPositionRow() async {
    final db = await database;
    final rows = await db.query('reading_position', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertReadingPosition({
    required String bookId,
    required int chapter,
    int? verse,
  }) async {
    final db = await database;
    await db.insert(
      'reading_position',
      {
        'id': 1,
        'book_id': bookId,
        'chapter': chapter,
        'verse': verse,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertChapterReadIfAbsent({
    required String bookId,
    required int chapter,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert(
      '''
      INSERT OR IGNORE INTO chapter_read (book_id, chapter, first_read_at)
      VALUES (?, ?, ?)
      ''',
      [bookId, chapter, now],
    );
  }

  Future<int> countChaptersReadForBook(String bookId) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM chapter_read WHERE book_id = ?',
      [bookId],
    );
    final n = r.first['c'] as int?;
    return n ?? 0;
  }

  Future<List<int>> listReadChaptersForBook(String bookId) async {
    final db = await database;
    final rows = await db.query(
      'chapter_read',
      columns: ['chapter'],
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    final nums = rows.map((m) => m['chapter'] as int).toList()..sort();
    return nums;
  }

  Future<Map<String, Object?>> getReadingStreakRow() async {
    final db = await database;
    final rows = await db.query('reading_streak', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      await db.insert('reading_streak', {
        'id': 1,
        'last_qualified_date': null,
        'current_streak': 0,
        'current_streak_start': null,
        'longest_streak': 0,
        'longest_streak_start': null,
        'longest_streak_end': null,
      });
      return (await db.query('reading_streak', where: 'id = ?', whereArgs: [1]))
          .first;
    }
    return rows.first;
  }

  Future<void> updateReadingStreakRow({
    String? lastQualifiedDate,
    required int currentStreak,
    String? currentStreakStart,
    required int longestStreak,
    String? longestStreakStart,
    String? longestStreakEnd,
  }) async {
    final db = await database;
    await db.update(
      'reading_streak',
      {
        'last_qualified_date': lastQualifiedDate,
        'current_streak': currentStreak,
        'current_streak_start': currentStreakStart,
        'longest_streak': longestStreak,
        'longest_streak_start': longestStreakStart,
        'longest_streak_end': longestStreakEnd,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<List<Bookmark>> getBookmarks(String bookId, int chapter) async {
    final db = await database;
    final rows = await db.query(
      'bookmarks',
      where: 'book_id = ? AND chapter = ? AND sync_status != ?',
      whereArgs: [bookId, chapter, SyncStatus.pendingDelete.name],
    );
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.insert('bookmarks', bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBookmark(int id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<List<Highlight>> getHighlights(String bookId, int chapter) async {
    final db = await database;
    final rows = await db.query(
      'highlights',
      where: 'book_id = ? AND chapter = ? AND sync_status != ?',
      whereArgs: [bookId, chapter, SyncStatus.pendingDelete.name],
    );
    return rows.map(Highlight.fromMap).toList();
  }

  Future<void> insertHighlight(Highlight highlight) async {
    final db = await database;
    await db.insert('highlights', highlight.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHighlight(Highlight highlight) async {
    final db = await database;
    await db.update('highlights', highlight.toMap(),
        where: 'id = ?', whereArgs: [highlight.id]);
  }

  Future<void> deleteHighlight(int id) async {
    final db = await database;
    await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<List<Note>> getNotes(String bookId, int chapter) async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'book_id = ? AND chapter = ? AND sync_status != ?',
      whereArgs: [bookId, chapter, SyncStatus.pendingDelete.name],
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final rows = await db.query(
      'bookmarks',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.pendingDelete.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<List<Highlight>> getAllHighlights() async {
    final db = await database;
    final rows = await db.query(
      'highlights',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.pendingDelete.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(Highlight.fromMap).toList();
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'sync_status != ?',
      whereArgs: [SyncStatus.pendingDelete.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
