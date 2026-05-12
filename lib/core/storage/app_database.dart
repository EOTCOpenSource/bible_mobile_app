import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../annotations/annotation_models.dart';

class AppDatabase {
  static const _dbName = 'bibleapp.db';
  static const _version = 1;

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
    return openDatabase(path, version: _version, onCreate: _onCreate);
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

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
