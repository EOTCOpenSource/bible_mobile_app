import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

import 'bible_storage.dart';
import 'catalog_database.dart';
import 'edition_manifest.dart';
import 'models/edition.dart';

/// Raised when an edition cannot be installed or updated.
class EditionException implements Exception {
  const EditionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Downloads, updates and removes Bible editions.
///
/// Two distribution channels, because the artefacts change at very different
/// rates: the databases live on GitHub Releases (rarely rebuilt, 8–14 MB each),
/// while `revisions.json` and the patch files are served from the site and
/// change every release.
class EditionManager {
  EditionManager({
    required this.storage,
    required this.catalog,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Where `revisions.json` and the patches are served.
  static const siteBase = 'https://80-weahadu.vercel.app';

  /// Where the databases are served. Kept off the site deploy so a release does
  /// not re-upload 191 MB of binaries.
  static const releaseBase =
      'https://github.com/EOTCOpenSource/80-weahadu/releases/latest/download';

  final BibleStorage storage;
  final CatalogDatabase catalog;
  final http.Client _client;

  EditionManifest? _manifest;

  // ── Manifest ───────────────────────────────────────────────────────────────

  /// Fetches `revisions.json`, revalidating rather than serving from cache.
  ///
  /// Returns null when the network is unavailable: the caller keeps serving
  /// local data and retries next launch, which is the whole point of shipping
  /// the text on device.
  Future<EditionManifest?> fetchManifest({bool force = false}) async {
    if (!force && _manifest != null) return _manifest;
    try {
      final res = await _client.get(
        Uri.parse('$siteBase/data/revisions.json'),
        headers: const {'Cache-Control': 'no-cache'},
      );
      if (res.statusCode != 200) {
        debugPrint('[EditionManager] manifest HTTP ${res.statusCode}');
        return null;
      }
      // Explicit UTF-8: the manifest carries no charset and `http` would
      // otherwise fall back to latin-1.
      return _manifest = EditionManifest.parse(utf8.decode(res.bodyBytes));
    } on Object catch (e) {
      debugPrint('[EditionManager] manifest unreachable: $e');
      return null;
    }
  }

  /// Every catalogued edition, annotated with what is on disk and what the
  /// server has. Sorted so installed editions come first.
  Future<List<EditionInstall>> list({bool refreshManifest = false}) async {
    final editions = await catalog.editions();
    final installed = await storage.installedEditionIds();
    final manifest = await fetchManifest(force: refreshManifest);

    final out = <EditionInstall>[];
    for (final e in editions) {
      final isInstalled = installed.contains(e.id);
      final local =
          isInstalled ? await storage.installedRevision(e.id) : null;
      final entry = manifest?[e.id];
      final remote = entry?.revision;

      final status = !isInstalled
          ? EditionStatus.notInstalled
          : (remote != null && local != null && remote > local)
              ? EditionStatus.updateAvailable
              : EditionStatus.installed;

      out.add(EditionInstall(
        edition: e,
        status: status,
        localRevision: local,
        remoteRevision: remote,
        downloadBytes: entry?.db?.bytes,
        isBundled: e.id == BibleStorage.bundledEditionId,
      ));
    }

    out.sort((a, b) {
      if (a.isInstalled != b.isInstalled) return a.isInstalled ? -1 : 1;
      return a.edition.id.compareTo(b.edition.id);
    });
    return out;
  }

  // ── Install ────────────────────────────────────────────────────────────────

  /// Downloads and installs an edition.
  ///
  /// The body is verified against the manifest's SHA-256 — which covers the
  /// *gzipped* file — while it streams, so a 14 MB download is checked without
  /// ever being held in memory whole. Output goes to a `.part` file and is
  /// renamed only once the checksum matches, so a killed download or a full
  /// disk can never leave a half database that opens and reads as corrupt.
  Future<void> install(
    String id, {
    void Function(double progress)? onProgress,
    CancellationToken? cancel,
  }) async {
    final manifest = await fetchManifest();
    final entry = manifest?[id];
    final db = entry?.db;
    if (manifest == null) {
      throw const EditionException('No connection to the update server.');
    }
    if (entry == null || db == null || db.file.isEmpty) {
      throw EditionException('Edition "$id" is not published.');
    }

    final target = await storage.editionFile(id);
    final part = File('${target.path}.part');
    if (part.existsSync()) await part.delete();

    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse('$releaseBase/${db.file}'));
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw EditionException(
          'Download failed (HTTP ${response.statusCode}). '
          'The release assets may not be published yet.',
        );
      }

      final total = response.contentLength ?? db.bytes;
      final hasher = Sha256Sink();
      var received = 0;

      final decompressed = response.stream.map((chunk) {
        if (cancel?.isCancelled ?? false) {
          throw const EditionException('Download cancelled.');
        }
        // Hash the compressed bytes — that is what the manifest records —
        // then let the same chunk go on to be decompressed.
        hasher.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
        return chunk;
      }).transform(gzip.decoder);

      sink = part.openWrite();
      await sink.addStream(decompressed);
      await sink.flush();
      await sink.close();
      sink = null;

      final digest = hasher.close();
      if (digest != db.sha256) {
        throw EditionException(
          'Checksum mismatch for $id — the download was corrupted.',
        );
      }

      if (target.existsSync()) await target.delete();
      await part.rename(target.path);
      debugPrint('[EditionManager] installed $id rev ${entry.revision}');
    } on Object {
      await sink?.close();
      if (part.existsSync()) await part.delete();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    if (id == BibleStorage.bundledEditionId) {
      throw const EditionException(
        'The bundled edition cannot be removed.',
      );
    }
    await storage.deleteEdition(id);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Brings an installed edition up to the server's revision.
  ///
  /// Resumable and idempotent: each revision commits separately, so a sync
  /// killed halfway restarts from the last complete revision rather than
  /// half-applying one, and re-applying a patch sets the same values.
  ///
  /// Returns the revision the edition ended on.
  Future<int> update(
    String id, {
    void Function(double progress)? onProgress,
  }) async {
    final manifest = await fetchManifest(force: true);
    final entry = manifest?[id];
    if (manifest == null || entry == null) return 0;

    if (!manifest.isSupported) {
      // A format we do not understand — take the whole database rather than
      // guessing at the patch semantics.
      debugPrint('[EditionManager] manifest schema ${manifest.schema} > '
          '${EditionManifest.supportedSchema}; full download');
      await install(id, onProgress: onProgress);
      return entry.revision;
    }

    final local = await storage.installedRevision(id);
    if (local == null) {
      await install(id, onProgress: onProgress);
      return entry.revision;
    }
    if (local >= entry.revision) return local;

    if (local < entry.baseline) {
      // Never patch across a baseline: below it the edits no longer describe
      // the difference between the two versions.
      debugPrint('[EditionManager] $id rev $local is below baseline '
          '${entry.baseline}; full download');
      await install(id, onProgress: onProgress);
      return entry.revision;
    }

    final file = await storage.editionFile(id);
    final steps = entry.revision - local;
    var applied = 0;

    // A separate writable connection; the reader's stays read-only.
    final db = sqlite3.open(file.path);
    try {
      for (var r = local + 1; r <= entry.revision; r++) {
        final res = await _client
            .get(Uri.parse('$siteBase/data/patches/$id/$r.json'));
        if (res.statusCode != 200) {
          // A gap in the chain — start over rather than skipping an edit.
          debugPrint('[EditionManager] patch $id/$r missing '
              '(HTTP ${res.statusCode}); full download');
          db.close();
          await install(id, onProgress: onProgress);
          return entry.revision;
        }
        _applyPatch(db, EditionPatch.parse(utf8.decode(res.bodyBytes)), r);
        applied++;
        onProgress?.call(applied / steps);
      }
    } finally {
      db.close();
    }
    return entry.revision;
  }

  /// Applies one patch inside a single transaction.
  ///
  /// The delete-then-insert around `verse_fts` is the part that is easy to get
  /// wrong: FTS5 external-content tables do not follow `UPDATE`s on the content
  /// table, so a plain update leaves the corrected verse searchable under its
  /// **old** wording forever. FTS5's own `integrity-check` will not catch it —
  /// it compares the index against itself, not against the content table — so
  /// this has to be right at write time.
  static void _applyPatch(Database db, EditionPatch patch, int revision) {
    db.execute('BEGIN');
    try {
      for (final op in patch.ops) {
        if (op.op != 'verse') {
          throw EditionException('Unknown patch op "${op.op}"');
        }

        if (op.isAlt) {
          db.execute(
            'UPDATE verse SET alt = ? WHERE book = ? AND chapter = ? AND verse = ?',
            [op.to, op.book, op.chapter, op.verse],
          );
          continue;
        }

        final old = db.select(
          'SELECT id, text FROM verse WHERE book = ? AND chapter = ? AND verse = ?',
          [op.book, op.chapter, op.verse],
        );
        if (old.isEmpty) continue;

        final rowId = old.first['id'];
        final oldText = old.first['text'];
        db.execute(
          "INSERT INTO verse_fts(verse_fts, rowid, text) VALUES('delete', ?, ?)",
          [rowId, oldText],
        );
        db.execute('UPDATE verse SET text = ? WHERE id = ?', [op.to, rowId]);
        db.execute(
          'INSERT INTO verse_fts(rowid, text) VALUES(?, ?)',
          [rowId, op.to],
        );
      }
      db.execute(
        "UPDATE meta SET value = ? WHERE key = 'revision'",
        ['$revision'],
      );
      db.execute('COMMIT');
      debugPrint('[EditionManager] ${patch.edition} → rev $revision '
          '(${patch.ops.length} ops)');
    } on Object {
      db.execute('ROLLBACK');
      rethrow;
    }
  }

  void dispose() => _client.close();
}

/// Lets the UI abort an in-flight download.
class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}
