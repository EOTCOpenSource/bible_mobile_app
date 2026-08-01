import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../annotations/annotation_models.dart';
import '../../features/books/data/models/book_identity.dart';

class AppDatabase {
  static const _dbName = 'bibleapp.db';
  static const _version = 7;

  /// Every table that keys user data on a book.
  static const _bookKeyedTables = [
    'bookmarks',
    'highlights',
    'notes',
    'reading_position',
    'chapter_read',
    'plan_position',
  ];

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
    if (oldVersion < 3) {
      await _migrateReadingPositionToMultiBook(db);
    }
    if (oldVersion < 4) {
      await _markLegacyBookIdsPendingUpdate(db);
    }
    if (oldVersion < 5) {
      await _createPlanPositionTable(db);
    }
    if (oldVersion < 6) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN has_seen_onboarding INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN has_seen_reader_hint INTEGER NOT NULL DEFAULT 0',
      );
    }
    await _migrateBookIdsToUsfm(db);
  }

  /// v6→v7: `book_id` moves from the English book name ("Genesis") to the USFM
  /// id ("GEN"), matching the SQLite Bible editions.
  ///
  /// The sync server and web frontend are untouched: they still speak
  /// kebab-case of the legacy name, and [SyncRepository] translates at the wire
  /// boundary. So nothing here needs re-pushing, and `remote_id` stays valid.
  ///
  /// Two deliberate choices about data safety:
  ///
  /// * `UPDATE OR IGNORE` — the annotation tables have `UNIQUE(book_id,
  ///   chapter, verse_start)`. If a device somehow holds both "Genesis" and
  ///   "genesis" for the same verse, the second update is skipped and that row
  ///   keeps its old id rather than being deleted.
  /// * Books with no USFM equivalent keep their existing `book_id`. `Teref
  ///   Baruch` (ተረፈ ባሮክ) is the real case: the 80-weahadu canon has no slot for
  ///   it, and mapping it onto `BAR` or `LJE` would silently move a reader's
  ///   notes into a different book.
  Future<void> _migrateBookIdsToUsfm(Database db) async {
    var moved = 0;
    var stranded = 0;

    for (final table in _bookKeyedTables) {
      final List<Map<String, Object?>> rows;
      try {
        rows = await db.rawQuery('SELECT DISTINCT book_id FROM $table');
      } on DatabaseException catch (e) {
        // A table added by a later migration than the one being upgraded from.
        debugPrint('[AppDatabase] v7: skipping $table ($e)');
        continue;
      }

      for (final row in rows) {
        final legacy = row['book_id'] as String?;
        if (legacy == null || legacy.isEmpty) continue;

        final usfm = usfmFromAnyBookId(legacy);
        if (usfm == legacy) {
          // Either already USFM, or a book we have no id for.
          if (!kUsfmToLegacyName.containsKey(legacy) &&
              !kUsfmToCanonSlug.containsKey(legacy)) {
            stranded++;
            debugPrint(
              '[AppDatabase] v7: no USFM id for "$legacy" in $table '
              '— left as is',
            );
          }
          continue;
        }

        moved += await db.rawUpdate(
          'UPDATE OR IGNORE $table SET book_id = ? WHERE book_id = ?',
          [usfm, legacy],
        );
      }
    }
    debugPrint(
      '[AppDatabase] v7: $moved rows moved to USFM ids, '
      '$stranded book ids left unmapped',
    );
  }

  /// v3→v4: annotation items pushed with title-case bookId (e.g. "Genesis")
  /// instead of the API's kebab-case ("genesis") need to be re-pushed so the
  /// server stores the correct format the web frontend can find.
  Future<void> _markLegacyBookIdsPendingUpdate(Database db) async {
    const sql = '''
      UPDATE {table} SET sync_status = 'pendingUpdate'
      WHERE remote_id IS NOT NULL
        AND sync_status = 'synced'
        AND (book_id != lower(book_id) OR book_id LIKE '% %')
    ''';
    for (final table in ['bookmarks', 'highlights', 'notes']) {
      await db.execute(sql.replaceFirst('{table}', table));
    }
  }

  /// v2→v3: replace single-row reading_position (id=1) with per-book rows.
  Future<void> _migrateReadingPositionToMultiBook(Database db) async {
    List<Map<String, Object?>> existing = [];
    try {
      existing = await db.query('reading_position');
    } catch (_) {}

    await db.execute('DROP TABLE IF EXISTS reading_position');
    await db.execute('''
      CREATE TABLE reading_position (
        book_id    TEXT    NOT NULL PRIMARY KEY,
        chapter    INTEGER NOT NULL,
        verse      INTEGER,
        updated_at INTEGER NOT NULL
      )
    ''');

    for (final row in existing) {
      final bookId = row['book_id'] as String?;
      final chapter = row['chapter'] as int?;
      if (bookId == null || chapter == null) continue;
      await db.insert('reading_position', {
        'book_id': bookId,
        'chapter': chapter,
        'verse': row['verse'],
        'updated_at':
            row['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// Reading progress + streak (v2). Used by [onCreate] and migration.
  Future<void> _createReadingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_position (
        book_id    TEXT    NOT NULL PRIMARY KEY,
        chapter    INTEGER NOT NULL,
        verse      INTEGER,
        updated_at INTEGER NOT NULL
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
    await db.insert('reading_streak', {
      'id': 1,
      'last_qualified_date': null,
      'current_streak': 0,
      'current_streak_start': null,
      'longest_streak': 0,
      'longest_streak_start': null,
      'longest_streak_end': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
    await _createPlanPositionTable(db);
    await _createSettingsTable(db);
  }

  Future<void> _createPlanPositionTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS plan_position (
      plan_id    TEXT    NOT NULL PRIMARY KEY,
      day_number INTEGER NOT NULL,
      book_id    TEXT    NOT NULL,
      chapter    INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  // ── Reading position / progress / streak ───────────────────────────────────

  Future<Map<String, Object?>?> getReadingPositionRow() async {
    final db = await database;
    final rows = await db.query(
      'reading_position',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, Object?>>> getAllReadingPositionRows() async {
    final db = await database;
    return db.query('reading_position', orderBy: 'updated_at DESC');
  }

  Future<void> upsertReadingPosition({
    required String bookId,
    required int chapter,
    int? verse,
  }) async {
    final db = await database;
    await db.insert('reading_position', {
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final rows = await db.query(
      'reading_streak',
      where: 'id = ?',
      whereArgs: [1],
    );
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
      return (await db.query(
        'reading_streak',
        where: 'id = ?',
        whereArgs: [1],
      )).first;
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
    await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.insert(
      'highlights',
      highlight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHighlight(Highlight highlight) async {
    final db = await database;
    await db.update(
      'highlights',
      highlight.toMap(),
      where: 'id = ?',
      whereArgs: [highlight.id],
    );
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
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
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
      orderBy: 'book_number ASC, chapter ASC, verse_start ASC',
    );
    return rows.map(Note.fromMap).toList();
  }

  // ── Sync helpers ───────────────────────────────────────────────────────────

  Future<void> updateAnnotationSync(
    String table,
    int id,
    SyncStatus status, {
    String? remoteId,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'sync_status': status.name};
    if (remoteId != null) values['remote_id'] = remoteId;
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteBookmark(int id, {required bool hasRemoteId}) async {
    final db = await database;
    if (hasRemoteId) {
      await db.update(
        'bookmarks',
        {'sync_status': SyncStatus.pendingDelete.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> softDeleteHighlight(int id, {required bool hasRemoteId}) async {
    final db = await database;
    if (hasRemoteId) {
      await db.update(
        'highlights',
        {'sync_status': SyncStatus.pendingDelete.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> softDeleteNote(int id, {required bool hasRemoteId}) async {
    final db = await database;
    if (hasRemoteId) {
      await db.update(
        'notes',
        {'sync_status': SyncStatus.pendingDelete.name},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Bookmark>> getPendingBookmarks() async {
    final db = await database;
    final rows = await db.query(
      'bookmarks',
      where: 'sync_status IN (?, ?, ?)',
      whereArgs: [
        SyncStatus.pendingCreate.name,
        SyncStatus.pendingUpdate.name,
        SyncStatus.pendingDelete.name,
      ],
    );
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<List<Note>> getPendingNotes() async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'sync_status IN (?, ?, ?)',
      whereArgs: [
        SyncStatus.pendingCreate.name,
        SyncStatus.pendingUpdate.name,
        SyncStatus.pendingDelete.name,
      ],
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<List<Highlight>> getPendingHighlights() async {
    final db = await database;
    final rows = await db.query(
      'highlights',
      where: 'sync_status IN (?, ?, ?)',
      whereArgs: [
        SyncStatus.pendingCreate.name,
        SyncStatus.pendingUpdate.name,
        SyncStatus.pendingDelete.name,
      ],
    );
    return rows.map(Highlight.fromMap).toList();
  }

  // ── Server pull upserts ────────────────────────────────────────────────────

  Future<void> upsertServerBookmarks(List<Bookmark> items) async {
    if (items.isEmpty) return;
    final db = await database;
    for (final b in items) {
      if (b.remoteId == null) continue;

      // Already tracked by remoteId — fix book_id if it was stored in the
      // wrong case from a previous pull
      final byRemoteId = await db.query(
        'bookmarks',
        where: 'remote_id = ?',
        whereArgs: [b.remoteId],
        limit: 1,
      );
      if (byRemoteId.isNotEmpty) {
        if ((byRemoteId.first['book_id'] as String) != b.bookId) {
          await db.update(
            'bookmarks',
            {'book_id': b.bookId},
            where: 'remote_id = ?',
            whereArgs: [b.remoteId],
          );
        }
        continue;
      }

      // Same verse exists locally (e.g. pendingCreate offline) — assign remoteId
      final byVerse = await db.query(
        'bookmarks',
        where: 'book_id = ? AND chapter = ? AND verse_start = ?',
        whereArgs: [b.bookId, b.chapter, b.verseStart],
        limit: 1,
      );
      if (byVerse.isNotEmpty) {
        await db.update(
          'bookmarks',
          {'remote_id': b.remoteId, 'sync_status': SyncStatus.synced.name},
          where: 'id = ?',
          whereArgs: [byVerse.first['id'] as int],
        );
      } else {
        await db.insert(
          'bookmarks',
          b.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> upsertServerHighlights(List<Highlight> items) async {
    if (items.isEmpty) return;
    final db = await database;
    for (final h in items) {
      if (h.remoteId == null) continue;

      // Already tracked by remoteId — update color/note if not locally modified;
      // also normalize book_id in case it was stored in wrong case
      final byRemoteId = await db.query(
        'highlights',
        where: 'remote_id = ?',
        whereArgs: [h.remoteId],
        limit: 1,
      );
      if (byRemoteId.isNotEmpty) {
        final updates = <String, dynamic>{};
        if ((byRemoteId.first['book_id'] as String) != h.bookId) {
          updates['book_id'] = h.bookId;
        }
        if ((byRemoteId.first['sync_status'] as String) ==
            SyncStatus.synced.name) {
          updates['color'] = h.color.toARGB32();
          updates['note'] = h.note;
        }
        if (updates.isNotEmpty) {
          await db.update(
            'highlights',
            updates,
            where: 'remote_id = ?',
            whereArgs: [h.remoteId],
          );
        }
        continue;
      }

      // Same verse exists locally — assign remoteId and sync server color
      final byVerse = await db.query(
        'highlights',
        where: 'book_id = ? AND chapter = ? AND verse_start = ?',
        whereArgs: [h.bookId, h.chapter, h.verseStart],
        limit: 1,
      );
      if (byVerse.isNotEmpty) {
        await db.update(
          'highlights',
          {
            'remote_id': h.remoteId,
            'sync_status': SyncStatus.synced.name,
            'color': h.color.toARGB32(),
            'note': h.note,
          },
          where: 'id = ?',
          whereArgs: [byVerse.first['id'] as int],
        );
      } else {
        await db.insert(
          'highlights',
          h.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> upsertServerNotes(List<Note> items) async {
    if (items.isEmpty) return;
    final db = await database;
    for (final n in items) {
      if (n.remoteId == null) continue;

      // Already tracked by remoteId — update content if not locally modified;
      // also normalize book_id in case it was stored in wrong case
      final byRemoteId = await db.query(
        'notes',
        where: 'remote_id = ?',
        whereArgs: [n.remoteId],
        limit: 1,
      );
      if (byRemoteId.isNotEmpty) {
        final updates = <String, dynamic>{};
        if ((byRemoteId.first['book_id'] as String) != n.bookId) {
          updates['book_id'] = n.bookId;
        }
        if ((byRemoteId.first['sync_status'] as String) ==
            SyncStatus.synced.name) {
          updates['content'] = n.content;
          updates['is_private'] = n.isPrivate ? 1 : 0;
        }
        if (updates.isNotEmpty) {
          await db.update(
            'notes',
            updates,
            where: 'remote_id = ?',
            whereArgs: [n.remoteId],
          );
        }
        continue;
      }

      // Same verse exists locally — assign remoteId and sync server content
      final byVerse = await db.query(
        'notes',
        where: 'book_id = ? AND chapter = ? AND verse_start = ?',
        whereArgs: [n.bookId, n.chapter, n.verseStart],
        limit: 1,
      );
      if (byVerse.isNotEmpty) {
        await db.update(
          'notes',
          {
            'remote_id': n.remoteId,
            'sync_status': SyncStatus.synced.name,
            'content': n.content,
            'is_private': n.isPrivate ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [byVerse.first['id'] as int],
        );
      } else {
        await db.insert(
          'notes',
          n.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  // ── Plan position ──────────────────────────────────────────────────────────

  Future<Map<String, Object?>?> getPlanPosition(String planId) async {
    final db = await database;
    final rows = await db.query(
      'plan_position',
      where: 'plan_id = ?',
      whereArgs: [planId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> savePlanPosition({
    required String planId,
    required int dayNumber,
    required String bookId,
    required int chapter,
  }) async {
    final db = await database;
    await db.insert('plan_position', {
      'plan_id': planId,
      'day_number': dayNumber,
      'book_id': bookId,
      'chapter': chapter,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS app_settings (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      daily_verse_enabled INTEGER NOT NULL DEFAULT 0,
      reading_time_enabled INTEGER NOT NULL DEFAULT 0,
      daily_verse_hour INTEGER,
      daily_verse_minute INTEGER,
      reading_time_hour INTEGER,
      reading_time_minute INTEGER,
      has_seen_onboarding INTEGER NOT NULL DEFAULT 0,
      has_seen_reader_hint INTEGER NOT NULL DEFAULT 0
    )
  ''');
    await db.insert('app_settings', {
      'id': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Fetch saved settings
  Future<Map<String, Object?>?> getSavedNotificationSettings() async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    return rows.isEmpty ? null : rows.first;
  }

  // Update saved settings
  Future<void> saveNotificationSettings({
    required bool dailyVerseEnabled,
    required bool readingTimeEnabled,
    int? dailyVerseHour,
    int? dailyVerseMinute,
    int? readingTimeHour,
    int? readingTimeMinute,
    bool hasSeenOnboarding = false,
    bool hasSeenReaderHint = false,
  }) async {
    final db = await database;
    await db.update(
      'app_settings',
      {
        'daily_verse_enabled': dailyVerseEnabled ? 1 : 0,
        'reading_time_enabled': readingTimeEnabled ? 1 : 0,
        'daily_verse_hour': dailyVerseHour,
        'daily_verse_minute': dailyVerseMinute,
        'reading_time_hour': readingTimeHour,
        'reading_time_minute': readingTimeMinute,
        'has_seen_onboarding': hasSeenOnboarding ? 1 : 0,
        'has_seen_reader_hint': hasSeenReaderHint ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
