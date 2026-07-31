import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import 'bible_storage.dart';
import 'models/edition.dart';

/// Localized name for one canon book.
class CanonBookName {
  const CanonBookName({required this.name, required this.abbr});
  final String name;
  final String abbr;
}

/// One slot in the 99-book canon registry.
class CanonBook {
  const CanonBook({
    required this.id,
    required this.ord,
    required this.slug,
    required this.nameEn,
    required this.testament,
    this.section,
  });

  final String id;
  final int ord;
  final String slug;
  final String nameEn;

  /// `old`, `deuterocanonical` or `new`.
  final String testament;

  /// `Pentateuch`, `Gospel`, … null for the deuterocanon's unsectioned slots.
  final String? section;
}

/// The bundled catalog: the edition list, the canon registry, and 418 book
/// names across five UI languages.
///
/// Small (70 KB) and always present, so an edition picker and a localized book
/// list can render before any edition is downloaded.
class CatalogDatabase {
  CatalogDatabase(this._storage);

  final BibleStorage _storage;

  Database? _db;
  List<Edition>? _editions;
  List<CanonBook>? _canon;
  final Map<String, Map<String, CanonBookName>> _namesByLang = {};

  Future<Database> _open() async {
    final cached = _db;
    if (cached != null) return cached;
    final file = await _storage.catalogFile();
    return _db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  }

  Future<List<Edition>> editions() async {
    final cached = _editions;
    if (cached != null) return cached;
    final db = await _open();
    final rows = db.select('SELECT * FROM edition');
    return _editions = rows.map(Edition.fromRow).toList(growable: false);
  }

  Future<Edition?> edition(String id) async {
    final all = await editions();
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<List<CanonBook>> canon() async {
    final cached = _canon;
    if (cached != null) return cached;
    final db = await _open();
    final rows = db.select(
      'SELECT id, ord, slug, name_en, testament, section FROM canon ORDER BY ord',
    );
    return _canon = rows
        .map((r) => CanonBook(
              id: r['id'] as String,
              ord: (r['ord'] as int?) ?? 0,
              slug: (r['slug'] as String?) ?? '',
              nameEn: (r['name_en'] as String?) ?? '',
              testament: (r['testament'] as String?) ?? '',
              section: r['section'] as String?,
            ))
        .toList(growable: false);
  }

  /// Book names for one UI language, keyed by USFM id.
  ///
  /// Languages present: `am`, `en`, `gez`, `om`, `ti`. Coverage is uneven —
  /// `om` and `ti` only name the protestant 66 — so callers must fall back to
  /// the edition's own book name.
  Future<Map<String, CanonBookName>> namesFor(String lang) async {
    final cached = _namesByLang[lang];
    if (cached != null) return cached;
    final db = await _open();
    final rows = db.select(
      'SELECT book, name, abbr FROM book_name WHERE lang = ?',
      [lang],
    );
    final map = {
      for (final r in rows)
        r['book'] as String: CanonBookName(
          name: (r['name'] as String?) ?? '',
          abbr: (r['abbr'] as String?) ?? '',
        ),
    };
    return _namesByLang[lang] = map;
  }

  /// Canon metadata keyed by USFM id.
  Future<Map<String, CanonBook>> canonById() async {
    final list = await canon();
    return {for (final c in list) c.id: c};
  }

  void dispose() {
    try {
      _db?.close();
    } on Object catch (e) {
      debugPrint('[CatalogDatabase] dispose: $e');
    }
    _db = null;
    _editions = null;
    _canon = null;
    _namesByLang.clear();
  }
}
