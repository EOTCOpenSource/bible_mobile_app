import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// TSK book abbreviation → USFM ID mapping.
const kTskAbbrevToUsfm = <String, String>{
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

class _RawRef {
  final int srcBook;
  final int srcCh;
  final int srcV;
  final int tgtBook;
  final int tgtCh;
  final int tgtV;
  final int? tgtToV;
  final int votes;

  _RawRef({
    required this.srcBook,
    required this.srcCh,
    required this.srcV,
    required this.tgtBook,
    required this.tgtCh,
    required this.tgtV,
    required this.tgtToV,
    required this.votes,
  });
}

void main(List<String> args) async {
  print('=== Treasury of Scripture Knowledge (TSK) Cross-Reference Builder ===');

  // 1. Decompress am-2000.db.gz to temporary file to read bounds via SQLite
  final dbGzFile = File('assets/bibles/am-2000.db.gz');
  if (!dbGzFile.existsSync()) {
    stderr.writeln('Error: assets/bibles/am-2000.db.gz not found.');
    exit(1);
  }

  final tempDbFile = File('${Directory.systemTemp.path}/temp_am2000_${DateTime.now().millisecondsSinceEpoch}.db');
  final decompressedDbBytes = gzip.decode(dbGzFile.readAsBytesSync());
  tempDbFile.writeAsBytesSync(decompressedDbBytes);

  final db = sqlite3.open(tempDbFile.path);

  // Read book positions and verse bounds
  final usfmToBookNumber = <String, int>{};
  final bookNumberToUsfm = <int, String>{};
  final maxChapters = <int, int>{};
  final verseBounds = <int, Map<int, int>>{};

  final bookRows = db.select('SELECT id, position, chapters FROM book ORDER BY position ASC');
  for (final row in bookRows) {
    final usfm = row['id'] as String;
    final pos = row['position'] as int;
    final chs = row['chapters'] as int;
    usfmToBookNumber[usfm] = pos;
    bookNumberToUsfm[pos] = usfm;
    maxChapters[pos] = chs;
    verseBounds[pos] = {};
  }

  final verseRows = db.select('SELECT book, chapter, max(verse) as max_v FROM verse GROUP BY book, chapter');
  for (final row in verseRows) {
    final usfm = row['book'] as String;
    final ch = row['chapter'] as int;
    final maxV = row['max_v'] as int;
    final pos = usfmToBookNumber[usfm];
    if (pos != null) {
      verseBounds[pos]?[ch] = maxV;
    }
  }

  db.dispose();
  if (tempDbFile.existsSync()) {
    tempDbFile.deleteSync();
  }

  print('Loaded database bounds for ${usfmToBookNumber.length} books.');

  // 2. Read raw TSK data
  File gzSource = File('tool/data/cross_references.txt.gz');
  if (!gzSource.existsSync()) {
    gzSource = File('/tmp/cross_references.txt.gz');
  }

  if (!gzSource.existsSync()) {
    stderr.writeln('Error: Raw TSK data cross_references.txt.gz not found.');
    exit(1);
  }

  final txtContent = utf8.decode(gzip.decode(gzSource.readAsBytesSync()));
  final lines = LineSplitter.split(txtContent);

  final rawRefs = <_RawRef>[];
  final maxVotesPerVerse = <String, int>{};

  for (final line in lines) {
    if (line.startsWith('From Verse') || line.trim().isEmpty) continue;
    final parts = line.split('\t');
    if (parts.length < 3) continue;

    final votes = int.tryParse(parts[2]) ?? 0;
    if (votes <= 0) continue; // Only positive votes

    // Parse source verse
    final fromParts = parts[0].split('.');
    if (fromParts.length < 3) continue;
    final srcUsfm = kTskAbbrevToUsfm[fromParts[0]];
    final srcCh = int.tryParse(fromParts[1]);
    final srcV = int.tryParse(fromParts[2]);
    if (srcUsfm == null || srcCh == null || srcV == null) continue;
    final srcBook = usfmToBookNumber[srcUsfm];
    if (srcBook == null) continue;

    // Validate source bounds
    final srcMaxCh = maxChapters[srcBook] ?? 0;
    final srcMaxV = verseBounds[srcBook]?[srcCh] ?? 0;
    if (srcCh < 1 || srcCh > srcMaxCh || srcV < 1 || srcV > srcMaxV) continue;

    // Parse target verse
    String targetLeft = parts[1];
    int? toVerse;
    if (parts[1].contains('-')) {
      final rangeParts = parts[1].split('-');
      targetLeft = rangeParts[0];
      final rightParts = rangeParts[1].split('.');
      if (rightParts.length >= 3) {
        toVerse = int.tryParse(rightParts[2]);
      } else if (rightParts.length == 1) {
        toVerse = int.tryParse(rightParts[0]);
      }
    }

    final toParts = targetLeft.split('.');
    if (toParts.length < 3) continue;
    final tgtUsfm = kTskAbbrevToUsfm[toParts[0]];
    final tgtCh = int.tryParse(toParts[1]);
    final tgtV = int.tryParse(toParts[2]);
    if (tgtUsfm == null || tgtCh == null || tgtV == null) continue;
    final tgtBook = usfmToBookNumber[tgtUsfm];
    if (tgtBook == null) continue;

    // Validate target bounds
    final tgtMaxCh = maxChapters[tgtBook] ?? 0;
    final tgtMaxV = verseBounds[tgtBook]?[tgtCh] ?? 0;
    if (tgtCh < 1 || tgtCh > tgtMaxCh || tgtV < 1 || tgtV > tgtMaxV) continue;

    if (toVerse != null && (toVerse < tgtV || toVerse > tgtMaxV)) {
      toVerse = tgtV;
    }

    rawRefs.add(_RawRef(
      srcBook: srcBook,
      srcCh: srcCh,
      srcV: srcV,
      tgtBook: tgtBook,
      tgtCh: tgtCh,
      tgtV: tgtV,
      tgtToV: toVerse,
      votes: votes,
    ));

    final verseKey = '$srcBook-$srcCh-$srcV';
    final currentMax = maxVotesPerVerse[verseKey] ?? 0;
    if (votes > currentMax) {
      maxVotesPerVerse[verseKey] = votes;
    }
  }

  print('Parsed ${rawRefs.length} valid cross-reference links.');

  // Group by source verse and calculate weights (0..10)
  final perBookData = <int, Map<String, List<Map<String, dynamic>>>>{};

  for (final ref in rawRefs) {
    final verseKey = '${ref.srcBook}-${ref.srcCh}-${ref.srcV}';
    final maxV = maxVotesPerVerse[verseKey] ?? 1;
    final weight = (ref.votes / maxV * 10).round().clamp(1, 10);

    // Assertion check: verify target resolves in bounds
    assert(ref.tgtBook > 0 && ref.tgtBook <= 94, 'Invalid target book number ${ref.tgtBook}');
    assert(ref.tgtCh > 0 && ref.tgtCh <= (maxChapters[ref.tgtBook] ?? 0), 'Target chapter out of range');
    assert(ref.tgtV > 0 && ref.tgtV <= (verseBounds[ref.tgtBook]?[ref.tgtCh] ?? 0), 'Target verse out of range');

    perBookData.putIfAbsent(ref.srcBook, () => {});
    final bookMap = perBookData[ref.srcBook]!;
    bookMap.putIfAbsent(verseKey, () => []);

    final entryObj = <String, dynamic>{
      'book': ref.tgtBook,
      'chapter': ref.tgtCh,
      'verse': ref.tgtV,
      if (ref.tgtToV != null) 'toVerse': ref.tgtToV,
      'weight': weight,
    };

    // Avoid exact duplicate target entries for same verse
    final existingList = bookMap[verseKey]!;
    final dupIndex = existingList.indexWhere((e) =>
        e['book'] == ref.tgtBook &&
        e['chapter'] == ref.tgtCh &&
        e['verse'] == ref.tgtV);

    if (dupIndex >= 0) {
      if (weight > (existingList[dupIndex]['weight'] as int)) {
        existingList[dupIndex] = entryObj;
      }
    } else {
      existingList.add(entryObj);
    }
  }

  // Sort references in each verse by weight descending
  for (final bookMap in perBookData.values) {
    for (final refList in bookMap.values) {
      refList.sort((a, b) {
        final wCompare = (b['weight'] as int).compareTo(a['weight'] as int);
        if (wCompare != 0) return wCompare;
        final bCompare = (a['book'] as int).compareTo(b['book'] as int);
        if (bCompare != 0) return bCompare;
        final cCompare = (a['chapter'] as int).compareTo(b['chapter'] as int);
        if (cCompare != 0) return cCompare;
        return (a['verse'] as int).compareTo(b['verse'] as int);
      });
    }
  }

  // Write sharded JSON files to assets/crossrefs/
  final outDir = Directory('assets/crossrefs');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  var totalSizeBytes = 0;

  // We write for all canon books 1..85
  for (var bNum = 1; bNum <= 85; bNum++) {
    final fileName = '${bNum.toString().padLeft(2, '0')}.json';
    final file = File('assets/crossrefs/$fileName');

    final dataMap = perBookData[bNum] ?? <String, List<Map<String, dynamic>>>{};
    final jsonStr = jsonEncode(dataMap);
    file.writeAsStringSync(jsonStr);

    final size = file.lengthSync();
    totalSizeBytes += size;
  }

  final totalMb = (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  print('Successfully wrote assets/crossrefs/ per-book JSON files.');
  print('Total assets/crossrefs/ size: $totalMb MB ($totalSizeBytes bytes).');
}
