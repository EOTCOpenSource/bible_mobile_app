/// One of the nine published Bible editions.
///
/// Catalog metadata (title, language, counts) comes from the bundled
/// `catalog.db`, so an edition can be listed, described and priced in the
/// downloader before a single byte of its text has been fetched.
class Edition {
  const Edition({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.abbrev,
    required this.language,
    required this.languageName,
    required this.script,
    required this.direction,
    required this.canon,
    required this.books,
    required this.chapters,
    required this.verses,
    required this.file,
    this.year,
    this.era,
    this.publisher,
  });

  /// `am-2000`, `en-kjv`, …
  final String id;

  /// Title in the edition's own language.
  final String title;
  final String titleEn;
  final String abbrev;

  /// BCP-47 language subtag: `am`, `gez`, `en`, `ti`, `om`.
  final String language;
  final String languageName;

  /// `Ethi` or `Latn`.
  final String script;
  final String direction;

  /// `eotc-81`, `kjv-81` or `protestant-66`.
  final String canon;

  final int books;
  final int chapters;
  final int verses;

  /// Database filename, e.g. `am-2000.db`.
  final String file;

  final int? year;
  final String? era;
  final String? publisher;

  /// Only `en-kjv` is public domain; every other edition is published by a
  /// Bible Society and named in [publisher].
  bool get isPublicDomain => id == 'en-kjv';

  String get yearLabel {
    if (year == null) return '';
    return era == null || era!.isEmpty ? '$year' : '$year $era';
  }

  factory Edition.fromRow(Map<String, Object?> r) => Edition(
        id: r['id'] as String,
        title: (r['title'] as String?) ?? '',
        titleEn: (r['title_en'] as String?) ?? '',
        abbrev: (r['abbrev'] as String?) ?? '',
        language: (r['language'] as String?) ?? '',
        languageName: (r['language_name'] as String?) ?? '',
        script: (r['script'] as String?) ?? 'Ethi',
        direction: (r['direction'] as String?) ?? 'ltr',
        canon: (r['canon'] as String?) ?? '',
        books: (r['books'] as int?) ?? 0,
        chapters: (r['chapters'] as int?) ?? 0,
        verses: (r['verses'] as int?) ?? 0,
        file: (r['file'] as String?) ?? '',
        year: r['year'] as int?,
        era: r['era'] as String?,
        publisher: r['publisher'] as String?,
      );
}

/// Install state of an edition on this device.
enum EditionStatus {
  /// Listed in the catalog, not on disk.
  notInstalled,

  downloading,

  /// On disk and openable.
  installed,

  /// On disk, and the server manifest has a newer revision.
  updateAvailable,
}

/// An edition plus what we know about the local copy.
class EditionInstall {
  const EditionInstall({
    required this.edition,
    required this.status,
    this.localRevision,
    this.remoteRevision,
    this.downloadBytes,
    this.progress,
    this.isBundled = false,
  });

  final Edition edition;
  final EditionStatus status;

  /// `meta.revision` of the installed copy, null when not installed.
  final int? localRevision;

  /// `revision` from the server manifest, null when the manifest is unread.
  final int? remoteRevision;

  /// Compressed download size from the manifest, for the size label.
  final int? downloadBytes;

  /// 0–1 while [status] is [EditionStatus.downloading], else null.
  final double? progress;

  /// Bundled editions ship inside the app and cannot be deleted.
  final bool isBundled;

  bool get isInstalled =>
      status == EditionStatus.installed ||
      status == EditionStatus.updateAvailable;

  EditionInstall copyWith({
    EditionStatus? status,
    int? localRevision,
    int? remoteRevision,
    int? downloadBytes,
    double? progress,
    bool clearProgress = false,
  }) =>
      EditionInstall(
        edition: edition,
        status: status ?? this.status,
        localRevision: localRevision ?? this.localRevision,
        remoteRevision: remoteRevision ?? this.remoteRevision,
        downloadBytes: downloadBytes ?? this.downloadBytes,
        progress: clearProgress ? null : (progress ?? this.progress),
        isBundled: isBundled,
      );
}
