import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Builds `assets/bibles/crossrefs.db.gz` from the openbible.info cross
/// references in `tool/data/cross_references.txt.gz`.
///
///     dart run tool/build_crossrefs.dart
///
/// Books are stored by USFM id (`JHN`), never by position: positions are each
/// edition's display order and move between editions.
///
/// Chapter and verse numbers are converted from the KJV numbering openbible
/// uses to the bundled am-2000 numbering, with the map in
/// `tool/data/kjv_to_am2000.json` (see `tool/versification/`). Without it
/// Psalms land a whole psalm away (am-2000 numbers them the Greek way),
/// Proverbs 25–31 point at chapters the Amharic Proverbs does not have, and a
/// few dozen chapters with different breaks land a verse or three off.
///
/// Bump `CrossRefStore.bundledStamp` in `lib/features/crossref/data/` whenever
/// this output changes, or installed copies keep the old data.

/// openbible abbreviation → USFM id.
const kOpenBibleToUsfm = <String, String>{
  'Gen': 'GEN', 'Exod': 'EXO', 'Lev': 'LEV', 'Num': 'NUM', 'Deut': 'DEU',
  'Josh': 'JOS', 'Judg': 'JDG', 'Ruth': 'RUT', '1Sam': '1SA', '2Sam': '2SA',
  '1Kgs': '1KI', '2Kgs': '2KI', '1Chr': '1CH', '2Chr': '2CH', 'Ezra': 'EZR',
  'Neh': 'NEH', 'Esth': 'EST', 'Job': 'JOB', 'Ps': 'PSA', 'Prov': 'PRO',
  'Eccl': 'ECC', 'Song': 'SNG', 'Isa': 'ISA', 'Jer': 'JER', 'Lam': 'LAM',
  'Ezek': 'EZK', 'Dan': 'DAN', 'Hos': 'HOS', 'Joel': 'JOL', 'Amos': 'AMO',
  'Obad': 'OBA', 'Jonah': 'JON', 'Mic': 'MIC', 'Nah': 'NAM', 'Hab': 'HAB',
  'Zeph': 'ZEP', 'Hag': 'HAG', 'Zech': 'ZEC', 'Mal': 'MAL', 'Matt': 'MAT',
  'Mark': 'MRK', 'Luke': 'LUK', 'John': 'JHN', 'Acts': 'ACT', 'Rom': 'ROM',
  '1Cor': '1CO', '2Cor': '2CO', 'Gal': 'GAL', 'Eph': 'EPH', 'Phil': 'PHP',
  'Col': 'COL', '1Thess': '1TH', '2Thess': '2TH', '1Tim': '1TI', '2Tim': '2TI',
  'Titus': 'TIT', 'Phlm': 'PHM', 'Heb': 'HEB', 'Jas': 'JAS', '1Pet': '1PE',
  '2Pet': '2PE', '1John': '1JN', '2John': '2JN', '3John': '3JN', 'Jude': 'JUD',
  'Rev': 'REV',
};

typedef Ref = ({String book, int chapter, int verse});

/// KJV → am-2000, from `tool/data/kjv_to_am2000.json`.
class Versification {
  Versification(this._moves);

  factory Versification.load(String path) {
    final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final moves = <String, Ref>{};
    for (final MapEntry(key: book, value: table) in raw.entries) {
      if (book.startsWith('_')) continue;
      for (final MapEntry(key: from, value: to) in (table as Map<String, dynamic>).entries) {
        // "3:16" stays in the book; "4MA 1:1" moves to another one.
        final target = to as String;
        final space = target.indexOf(' ');
        final toBook = space < 0 ? book : target.substring(0, space);
        final cv = (space < 0 ? target : target.substring(space + 1)).split(':');
        moves['$book $from'] = (
          book: toBook,
          chapter: int.parse(cv[0]),
          verse: int.parse(cv[1]),
        );
      }
    }
    return Versification(moves);
  }

  final Map<String, Ref> _moves;

  Ref apply(Ref kjv) =>
      _moves['${kjv.book} ${kjv.chapter}:${kjv.verse}'] ?? kjv;

  int get size => _moves.length;
}

Ref? parseRef(String s) {
  final parts = s.split('.');
  if (parts.length < 3) return null;
  final book = kOpenBibleToUsfm[parts[0]];
  final chapter = int.tryParse(parts[1]);
  final verse = int.tryParse(parts[2]);
  if (book == null || chapter == null || verse == null) return null;
  return (book: book, chapter: chapter, verse: verse);
}

void main() {
  stdout.writeln('=== openbible.info cross references → assets/bibles/crossrefs.db.gz ===');

  // 1. Which verses exist in am-2000, so nothing points into a gap.
  final (am, amFile) = _openGz('assets/bibles/am-2000.db.gz');
  final exists = <String>{};
  for (final row in am.select('SELECT book, chapter, verse FROM verse WHERE verse > 0')) {
    exists.add('${row['book']} ${row['chapter']}:${row['verse']}');
  }
  am.close();
  amFile.deleteSync();
  bool known(Ref r) => exists.contains('${r.book} ${r.chapter}:${r.verse}');

  final map = Versification.load('tool/data/kjv_to_am2000.json');
  stdout.writeln('am-2000 verses: ${exists.length}; renumbered by map: ${map.size}');

  // 2. Parse, renumber, keep the strongest vote for any duplicate pair (two
  // KJV verses can fold into one Amharic verse).
  final text = utf8.decode(
      gzip.decode(File('tool/data/cross_references.txt.gz').readAsBytesSync()));
  final rows = <String, List<Object>>{};
  var skippedVotes = 0, skippedMissing = 0;
  for (final line in const LineSplitter().convert(text)) {
    if (line.isEmpty || line.startsWith('From Verse')) continue;
    final cols = line.split('\t');
    if (cols.length < 3) continue;
    final votes = int.tryParse(cols[2]) ?? 0;
    // Zero and negative votes are links readers looked at and rejected.
    if (votes <= 0) {
      skippedVotes++;
      continue;
    }
    final fromKjv = parseRef(cols[0]);
    final range = cols[1].split('-');
    final toKjv = parseRef(range[0]);
    if (fromKjv == null || toKjv == null) continue;
    final from = map.apply(fromKjv);
    final to = map.apply(toKjv);
    if (!known(from) || !known(to)) {
      skippedMissing++;
      continue;
    }

    // A range end is renumbered on its own; keep it only if it still reads as
    // a forward range inside the same book.
    int? endChapter, endVerse;
    if (range.length > 1) {
      final endKjv = parseRef(range[1]);
      if (endKjv != null) {
        final end = map.apply(endKjv);
        final forward = end.book == to.book &&
            (end.chapter > to.chapter ||
                (end.chapter == to.chapter && end.verse > to.verse));
        if (forward && known(end)) {
          endChapter = end.chapter;
          endVerse = end.verse;
        }
      }
    }

    final key = '${from.book} ${from.chapter}:${from.verse}>${to.book} ${to.chapter}:${to.verse}';
    final previous = rows[key];
    if (previous != null && (previous[8] as int) >= votes) continue;
    rows[key] = [
      from.book, from.chapter, from.verse,
      to.book, to.chapter, to.verse,
      endChapter ?? to.chapter, endVerse ?? to.verse,
      votes,
    ];
  }
  stdout.writeln('kept ${rows.length} links; dropped $skippedVotes unvoted, '
      '$skippedMissing pointing outside am-2000');

  // 3. Write the database. WITHOUT ROWID on the lookup key: the table is its
  // own index, which is most of what keeps it small.
  final tmp = File('${Directory.systemTemp.path}/crossrefs_$pid.db');
  if (tmp.existsSync()) tmp.deleteSync();
  final db = sqlite3.open(tmp.path);
  db.execute('''
    CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT) WITHOUT ROWID;
    CREATE TABLE cross_ref (
      book TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL,
      to_book TEXT NOT NULL, to_chapter INTEGER NOT NULL, to_verse INTEGER NOT NULL,
      to_chapter_end INTEGER NOT NULL, to_verse_end INTEGER NOT NULL,
      votes INTEGER NOT NULL,
      PRIMARY KEY (book, chapter, verse, to_book, to_chapter, to_verse)
    ) WITHOUT ROWID;
  ''');
  db.execute('BEGIN');
  final insert = db.prepare('INSERT INTO cross_ref VALUES (?,?,?,?,?,?,?,?,?)');
  for (final r in rows.values) {
    insert.execute(r);
  }
  insert.close();
  final meta = db.prepare('INSERT INTO meta VALUES (?, ?)');
  meta.execute(['source', 'openbible.info cross references (CC-BY)']);
  meta.execute(['versification', 'am-2000']);
  meta.execute(['links', '${rows.length}']);
  meta.close();
  db.execute('COMMIT');
  db.execute('VACUUM');
  db.close();

  final out = File('assets/bibles/crossrefs.db.gz');
  out.writeAsBytesSync(GZipCodec(level: 9).encode(tmp.readAsBytesSync()));
  final rawMb = tmp.lengthSync() / (1024 * 1024);
  tmp.deleteSync();
  stdout.writeln('wrote ${out.path}: '
      '${(out.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB '
      '(${rawMb.toStringAsFixed(2)} MB unpacked)');
}

(Database, File) _openGz(String path) {
  final tmp = File('${Directory.systemTemp.path}/am2000_$pid.db');
  tmp.writeAsBytesSync(gzip.decode(File(path).readAsBytesSync()));
  return (sqlite3.open(tmp.path, mode: OpenMode.readOnly), tmp);
}
