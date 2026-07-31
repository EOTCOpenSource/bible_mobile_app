/// Book identity across the three vocabularies this app has to speak.
///
/// | vocabulary | example | who uses it |
/// |---|---|---|
/// | USFM id | `GEN`, `1ES` | the 80-weahadu SQLite editions, and every local table |
/// | legacy English name | `Genesis`, `3 Book of Ezra` | what `book_id` held before the SQLite migration |
/// | API kebab id | `genesis`, `3-book-of-ezra` | the sync server and the web frontend |
///
/// The API vocabulary is **not** the canon slug. The server stores kebab-case
/// of the *legacy* English name (`book-of-tobit`, `thr-letter-of-jeremiah`),
/// which the web frontend already reads. Changing it would orphan every
/// annotation the web app has written, so the wire format is frozen and we
/// translate at the sync boundary instead.
library;

/// USFM id → the English name the app used before the SQLite migration.
///
/// Covers exactly the 81 books that shipped in the old
/// `assets/bibledata/index.json`, which this migration deleted.
/// Books that only exist in the SQLite editions (the Ethiopic appendix, the
/// Greek Esther fragments, the KJV-specific deuterocanon) are absent by design
/// — they never had a legacy name to preserve.
const kUsfmToLegacyName = <String, String>{
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'JUB': 'Jubilees',
  'ENO': 'Enoch',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  // The legacy index numbered the two Ezra apocalypses 19/20 and named them
  // confusingly; the Amharic names are what disambiguate them.
  '1ES': '3 Book of Ezra', // መጽሐፈ ዕዝራ ሱቱኤል
  '2ES': '2nd Book of Ezra', // መጽሐፈ ዕዝራ ካልእ
  'TOB': 'Book of Tobit',
  'JDT': 'Book of Judith',
  'EST': 'Esther',
  '1MA': '1 Maccabees',
  '2MA': '2 Maccabees',
  '3MA': '3 Maccabees',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  '4MA': 'Book of Admonition', // መጽሐፈ ተግሣጽ
  'WIS': 'Wisdom of Solomon',
  'ECC': 'Ecclesiastes',
  'SNG': 'Song of Solomon',
  'SIR': 'book of sirach', // lowercase in the legacy index; kept verbatim
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'BAR': 'Baruch',
  'LAM': 'Lamentations',
  'LJE': 'Thr letter of Jeremiah', // typo is in the legacy index; kept verbatim
  'EZK': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'AMO': 'Amos',
  'MIC': 'Micah',
  'JOL': 'Joel',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'NAM': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MRK': 'Mark',
  'LUK': 'Luke',
  'JHN': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHP': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JN': '1 John',
  '2JN': '2 John',
  '3JN': '3 John',
  'JAS': 'James',
  'JUD': 'Jude',
  'REV': 'Revelation',
};

/// Legacy English name (lowercased) → USFM id.
///
/// `Teref Baruch` (ተረፈ ባሮክ, legacy book 40) has no entry: the 80-weahadu canon
/// has no slot for it, and `BAR`/`LJE` are different works. Rows keyed on it
/// survive the migration untranslated rather than being silently reassigned to
/// the wrong book — see `AppDatabase._migrateBookIdsToUsfm`.
final Map<String, String> kLegacyNameToUsfm = {
  for (final e in kUsfmToLegacyName.entries) e.value.toLowerCase(): e.key,
};

/// Canon slug for every book in the 99-slot registry, used as the API id for
/// books that predate no legacy name. Mirrors `canon.slug` in `catalog.db`.
const kUsfmToCanonSlug = <String, String>{
  'ESG': 'esther-greek',
  'S3Y': 'seleste-dekik',
  'SUS': 'susanna',
  'MAN': 'prayer-of-manasseh',
  'DAG': 'teref-daniel',
  'OTH': '1-covenant',
  'XXG': 'sirate-tsion',
  'XXA': 'josippon',
  'XXC': 'didascalia',
  'XXB': '1-clement',
  'XXD': 'tizaz',
  'XXE': 'abtilis',
  'XXF': 'gitsew',
  'LAO': '2-covenant',
  'LJE-KJV': 'jeremys-letter',
  '1ES-KJV': '1-esdras',
  '2ES-KJV': '2-esdras',
  '1MA-KJV': '1-maccabees-greek',
  '2MA-KJV': '2-maccabees-greek',
};

/// USFM id → English abbreviation.
///
/// **Frozen.** `catalog.db` has no English abbreviations at all — `book_name`
/// carries `abbr` for `am`, `gez`, `om` and `ti`, and NULL for all 99 English
/// rows — so without this table English abbreviations would fall back to the
/// edition's own, which for `am-2000` is Ethiopic ("ዘፍጥ").
///
/// It is also what verse deep links are built from. A link shared to Telegram
/// last year still resolves because the slug comes from here and not from
/// whatever the active edition happens to call the book. Never change an entry;
/// only add.
const kUsfmToEnAbbrev = <String, String>{
  'GEN': 'Gen', 'EXO': 'Exod', 'LEV': 'Lev', 'NUM': 'Num', 'DEU': 'Deut',
  'JOS': 'Josh', 'JDG': 'Judg', 'RUT': 'Ruth', '1SA': '1 Sam', '2SA': '2 Sam',
  '1KI': '1 Kgs', '2KI': '2 Kgs', '1CH': '1 Chron', '2CH': '2 Chron',
  'JUB': 'Jubil', 'ENO': 'Enoch', 'EZR': 'Ezra', 'NEH': 'Neh', '1ES': '3 Ezr',
  '2ES': '2 Ezr', 'TOB': 'tobit', 'JDT': 'Judith', 'EST': 'Esth',
  '1MA': '1 Mecca', '2MA': '2 Mecca', '3MA': '3 Mecca', 'JOB': 'Job',
  'PSA': 'Ps', 'PRO': 'Prov', '4MA': 'admo', 'WIS': 'wisd', 'ECC': 'Ecc',
  'SNG': 'Song', 'SIR': 'Sir', 'ISA': 'Isa', 'JER': 'Jer', 'BAR': 'Baru',
  'LAM': 'Lam', 'LJE': 'Let Jer', 'EZK': 'Ezek', 'DAN': 'Dan', 'HOS': 'Hos',
  'AMO': 'Amos', 'MIC': 'Micah', 'JOL': 'Joel', 'OBA': 'Obad', 'JON': 'Jonah',
  'NAM': 'Nahum', 'HAB': 'Hab', 'ZEP': 'Zeph', 'HAG': 'Hag', 'ZEC': 'Zech',
  'MAL': 'Mal', 'MAT': 'Matt', 'MRK': 'Mark', 'LUK': 'Luke', 'JHN': 'John',
  'ACT': 'Acts', 'ROM': 'Rom', '1CO': '1 Cor', '2CO': '2 Cor', 'GAL': 'Gal',
  'EPH': 'Eph', 'PHP': 'Phil', 'COL': 'Col', '1TH': '1 Thess',
  '2TH': '2 Thess', '1TI': '1 Tim', '2TI': '2 Tim', 'TIT': 'Titus',
  'PHM': 'Philem', 'HEB': 'Heb', '1PE': '1 Pet', '2PE': '2 Pet',
  '1JN': '1 John', '2JN': '2 John', '3JN': '3 John', 'JAS': 'James',
  'JUD': 'Jud', 'REV': 'Rev',
  // Books with no legacy abbreviation; these have never appeared in a shared
  // link, so the id itself is a fine slug.
  'ESG': 'Esg', 'S3Y': 'S3y', 'SUS': 'Sus', 'MAN': 'Man', 'DAG': 'Dag',
  'OTH': 'Oth', 'XXG': 'Xxg', 'XXA': 'Xxa', 'XXC': 'Xxc', 'XXB': 'Xxb',
  'XXD': 'Xxd', 'XXE': 'Xxe', 'XXF': 'Xxf', 'LAO': 'Lao',
};

/// English abbreviation for a book, falling back to the id so a book from a
/// future edition still renders something short.
String enAbbrevFromUsfm(String usfm) =>
    kUsfmToEnAbbrev[usfm] ?? usfm;

/// The book half of a verse deep link: lowercase, no spaces (`jer`, `1sam`).
String deepLinkSlugFromUsfm(String usfm) =>
    enAbbrevFromUsfm(usfm).toLowerCase().replaceAll(' ', '');

final Map<String, String> _deepLinkSlugToUsfm = {
  for (final usfm in kUsfmToEnAbbrev.keys) deepLinkSlugFromUsfm(usfm): usfm,
};

/// Reverses [deepLinkSlugFromUsfm]; null when the slug names no known book.
String? usfmFromDeepLinkSlug(String slug) =>
    _deepLinkSlugToUsfm[slug.toLowerCase().replaceAll(' ', '')];

String _kebab(String s) => s.toLowerCase().replaceAll(' ', '-');

/// USFM id → the kebab-case id the sync API and web frontend expect.
///
/// Falls back to the canon slug for books that never had a legacy name, and to
/// the lowercased id itself for anything unrecognised, so a new book in a
/// future edition round-trips instead of throwing.
String apiBookIdFromUsfm(String usfm) {
  final legacy = kUsfmToLegacyName[usfm];
  if (legacy != null) return _kebab(legacy);
  return kUsfmToCanonSlug[usfm] ?? usfm.toLowerCase();
}

final Map<String, String> _apiIdToUsfm = {
  for (final usfm in kUsfmToLegacyName.keys) apiBookIdFromUsfm(usfm): usfm,
  for (final e in kUsfmToCanonSlug.entries) e.value: e.key,
};

/// Anything the server or an older local row might hold → USFM id.
///
/// Accepts the API kebab form (`1-samuel`), the legacy title-case name
/// (`1 Samuel`), and a USFM id that is already correct. Returns the input
/// unchanged when nothing matches, so unknown values stay visible rather than
/// collapsing onto Genesis.
String usfmFromAnyBookId(String raw) {
  if (raw.isEmpty) return raw;
  if (kUsfmToLegacyName.containsKey(raw) ||
      kUsfmToCanonSlug.containsKey(raw)) {
    return raw;
  }
  final kebab = _kebab(raw);
  return _apiIdToUsfm[kebab] ?? kLegacyNameToUsfm[raw.toLowerCase()] ?? raw;
}
