import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Where edition databases live on disk, and how they get there.
///
/// Application *support* rather than documents: these are re-downloadable
/// caches the user never browses, and on iOS documents are exposed to Files and
/// backed up to iCloud, which a 30 MB regenerable database has no business
/// being in.
class BibleStorage {
  /// The edition bundled with the app. Always installable offline.
  static const bundledEditionId = 'am-2000';

  /// `meta.revision` of the bundled `am-2000.db.gz` asset.
  ///
  /// Guards the reinstall check: a copy already patched past this revision is
  /// left alone, so shipping an app update never rolls a synced edition back.
  /// Bump this whenever the bundled asset is regenerated.
  static const bundledEditionRevision = 2;

  /// Changes whenever `catalog.db.gz` is re-bundled. The catalog carries no
  /// revision of its own, so a stamp file is what tells us to replace it.
  static const bundledCatalogStamp = '2026-07-30';

  static const _assetDir = 'assets/bibles';

  /// Overrides the storage root. For tests, which have no `path_provider`
  /// implementation and would otherwise need the platform channel.
  BibleStorage({Directory? rootOverride}) : _root = rootOverride;

  Directory? _root;

  /// `<app support>/bibles`, created on first use.
  Future<Directory> root() async {
    final cached = _root;
    if (cached != null) {
      if (!cached.existsSync()) await cached.create(recursive: true);
      return cached;
    }
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'bibles'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _root = dir;
  }

  Future<File> editionFile(String id) async =>
      File(p.join((await root()).path, '$id.db'));

  Future<File> catalogFile() async =>
      File(p.join((await root()).path, 'catalog.db'));

  Future<File> _catalogStampFile() async =>
      File(p.join((await root()).path, 'catalog.stamp'));

  Future<bool> isInstalled(String id) async =>
      (await editionFile(id)).exists();

  /// Installed editions, by id.
  Future<Set<String>> installedEditionIds() async {
    final dir = await root();
    if (!dir.existsSync()) return {};
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => p.basename(f.path))
        .where((n) => n.endsWith('.db') && n != 'catalog.db')
        .map((n) => n.substring(0, n.length - 3))
        .toSet();
  }

  /// Deletes an edition and the journal files SQLite may have left beside it.
  Future<void> deleteEdition(String id) async {
    final file = await editionFile(id);
    for (final path in [file.path, '${file.path}-wal', '${file.path}-shm']) {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    }
  }

  Future<int> editionSizeOnDisk(String id) async {
    final f = await editionFile(id);
    return f.existsSync() ? f.length() : 0;
  }

  // ── First-run install from bundled assets ──────────────────────────────────

  /// Unpacks the bundled catalog and default edition if they are missing or
  /// older than what ships with this build. Safe to call on every launch.
  Future<void> ensureBundledInstalled() async {
    await _ensureCatalog();
    await _ensureBundledEdition();
  }

  Future<void> _ensureCatalog() async {
    final file = await catalogFile();
    final stamp = await _catalogStampFile();
    final current = file.existsSync() && stamp.existsSync()
        ? await stamp.readAsString()
        : null;
    if (current == bundledCatalogStamp) return;

    await _installAsset('$_assetDir/catalog.db.gz', file);
    await stamp.writeAsString(bundledCatalogStamp, flush: true);
    debugPrint('[BibleStorage] catalog installed ($bundledCatalogStamp)');
  }

  Future<void> _ensureBundledEdition() async {
    final file = await editionFile(bundledEditionId);

    if (file.existsSync()) {
      final installed = _readRevision(file.path);
      // A copy patched past the bundled revision is ahead of this build.
      // Overwriting it would roll the user backwards — leave it alone.
      if (installed != null && installed >= bundledEditionRevision) return;
      debugPrint('[BibleStorage] bundled edition rev $bundledEditionRevision '
          'supersedes installed rev $installed — reinstalling');
    }

    await _installAsset('$_assetDir/$bundledEditionId.db.gz', file);
    debugPrint('[BibleStorage] $bundledEditionId installed');
  }

  /// Gunzips an asset to [target] via a `.part` file, so a kill mid-write can
  /// never leave a truncated database that later opens and reads as corrupt.
  ///
  /// Decompression streams straight into the file sink — 14 MB in, 30 MB out —
  /// rather than materialising the whole database in memory. It stays on this
  /// isolate on purpose: `compute` would move the work off the UI thread, but
  /// `flutter_test` never delivers an isolate's response port, so any widget
  /// test that starts the app would hang instead of failing.
  Future<void> _installAsset(String assetKey, File target) async {
    final data = await rootBundle.load(assetKey);
    final gz = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    final part = File('${target.path}.part');
    final sink = part.openWrite();
    try {
      await sink.addStream(
        Stream<List<int>>.value(gz).transform(gzip.decoder),
      );
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (target.existsSync()) await target.delete();
    await part.rename(target.path);
  }

  /// Reads `meta.revision` without holding the database open.
  ///
  /// Returns null when the file is unreadable or has no revision, which the
  /// callers treat as "older than anything" so a damaged file gets replaced.
  int? _readRevision(String path) {
    Database? db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
      final rows =
          db.select("SELECT value FROM meta WHERE key = 'revision'");
      if (rows.isEmpty) return null;
      return int.tryParse(rows.first['value'] as String);
    } on Object catch (e) {
      debugPrint('[BibleStorage] cannot read revision from $path: $e');
      return null;
    } finally {
      db?.close();
    }
  }

  /// Public form of [_readRevision] for the sync layer.
  Future<int?> installedRevision(String id) async {
    final file = await editionFile(id);
    if (!file.existsSync()) return null;
    return _readRevision(file.path);
  }
}

/// Incremental SHA-256 over a byte stream, so a 14 MB download is verified
/// without ever holding the whole compressed body in memory.
class Sha256Sink {
  Sha256Sink() {
    _inner = sha256.startChunkedConversion(_out);
  }

  final _out = _DigestCollector();
  late final ByteConversionSink _inner;

  void add(List<int> chunk) => _inner.add(chunk);

  String close() {
    _inner.close();
    return _out.digest.toString();
  }
}

class _DigestCollector implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
