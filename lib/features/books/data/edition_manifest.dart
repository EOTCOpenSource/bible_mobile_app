import 'dart:convert';

/// The `db` block of one manifest entry.
class ManifestDb {
  const ManifestDb({
    required this.file,
    required this.bytes,
    required this.sha256,
  });

  /// Release asset filename, e.g. `am-2000.db.gz`.
  final String file;

  /// Compressed size in bytes.
  final int bytes;

  /// SHA-256 of the **gzipped** file, matching what `release.py` records.
  final String sha256;

  factory ManifestDb.fromJson(Map<String, dynamic> j) => ManifestDb(
        file: (j['file'] as String?) ?? '',
        bytes: (j['bytes'] as num?)?.toInt() ?? 0,
        sha256: (j['sha256'] as String?) ?? '',
      );
}

/// One edition's entry in `revisions.json`.
class ManifestEntry {
  const ManifestEntry({
    required this.id,
    required this.revision,
    required this.baseline,
    required this.patches,
    this.db,
  });

  final String id;

  /// Current data version on the server.
  final int revision;

  /// Oldest revision that can still catch up by patching. A local copy below
  /// this must be downloaded afresh — patches describe edits, and below the
  /// baseline the edits no longer describe the difference.
  final int baseline;

  /// Which patch files exist.
  final List<int> patches;

  final ManifestDb? db;

  factory ManifestEntry.fromJson(String id, Map<String, dynamic> j) =>
      ManifestEntry(
        id: id,
        revision: (j['revision'] as num?)?.toInt() ?? 0,
        baseline: (j['baseline'] as num?)?.toInt() ?? 0,
        patches: ((j['patches'] as List?) ?? const [])
            .whereType<num>()
            .map((n) => n.toInt())
            .toList(),
        db: j['db'] is Map<String, dynamic>
            ? ManifestDb.fromJson(j['db'] as Map<String, dynamic>)
            : null,
      );
}

/// A parsed `revisions.json`.
class EditionManifest {
  const EditionManifest({
    required this.schema,
    required this.generated,
    required this.editions,
  });

  /// Format version of the manifest itself. Higher than [supportedSchema]
  /// means stop and full-download rather than guessing at a format we do not
  /// understand.
  final int schema;

  final String generated;
  final Map<String, ManifestEntry> editions;

  /// The highest manifest schema this client can interpret.
  static const supportedSchema = 1;

  bool get isSupported => schema <= supportedSchema;

  ManifestEntry? operator [](String id) => editions[id];

  factory EditionManifest.parse(String body) {
    final root = jsonDecode(body) as Map<String, dynamic>;
    final raw = (root['editions'] as Map?) ?? const {};
    return EditionManifest(
      schema: (root['schema'] as num?)?.toInt() ?? 0,
      generated: (root['generated'] as String?) ?? '',
      editions: {
        for (final e in raw.entries)
          if (e.value is Map<String, dynamic>)
            e.key as String:
                ManifestEntry.fromJson(e.key as String, e.value as Map<String, dynamic>),
      },
    );
  }
}

/// A single edit in a patch file.
class PatchOp {
  const PatchOp({
    required this.op,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.field,
    required this.to,
  });

  /// `verse` is the only op defined today. An unknown op is a signal to
  /// full-download, not to skip silently.
  final String op;

  final String book;
  final int chapter;
  final int verse;

  /// `t` → `verse.text`, `alt` → `verse.alt`.
  final String field;

  final String to;

  bool get isAlt => field == 'alt';

  factory PatchOp.fromJson(Map<String, dynamic> j) => PatchOp(
        op: (j['op'] as String?) ?? '',
        book: (j['book'] as String?) ?? '',
        chapter: (j['chapter'] as num?)?.toInt() ?? 0,
        verse: (j['verse'] as num?)?.toInt() ?? 0,
        field: (j['field'] as String?) ?? 't',
        to: (j['to'] as String?) ?? '',
      );
}

class EditionPatch {
  const EditionPatch({
    required this.edition,
    required this.from,
    required this.to,
    required this.ops,
  });

  final String edition;
  final int from;
  final int to;
  final List<PatchOp> ops;

  factory EditionPatch.parse(String body) {
    final root = jsonDecode(body) as Map<String, dynamic>;
    return EditionPatch(
      edition: (root['edition'] as String?) ?? '',
      from: (root['from'] as num?)?.toInt() ?? 0,
      to: (root['to'] as num?)?.toInt() ?? 0,
      ops: ((root['ops'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PatchOp.fromJson)
          .toList(),
    );
  }
}
