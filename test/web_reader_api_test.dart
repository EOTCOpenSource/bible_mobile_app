import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bibleflutter/core/storage/app_database.dart';
import 'package:bibleflutter/core/web_reader/api_router.dart';
import 'package:bibleflutter/core/web_reader/local_server_service.dart';
import 'package:bibleflutter/core/web_reader/web_fonts.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

/// Exercises the Local Web Reader's API against the real bundled edition and a
/// real annotation database, without opening a socket: the handler is a plain
/// function, so every route can be driven with a [Request].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmpDir;
  late Directory dbDir;
  late AppDatabase db;
  late BibleRepository bible;
  late Handler handler;

  setUpAll(() async {
    // `flutter test` runs test files in parallel, and every file that opens an
    // AppDatabase otherwise lands on the same `bibleapp.db` under `.dart_tool`.
    // Giving this file its own directory keeps it from fighting the other
    // suites over the same file — and from seeing their rows.
    dbDir = await Directory.systemTemp.createTemp('web_reader_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  tearDownAll(() {
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('web_reader_test');
    db = AppDatabase();

    final raw = await db.database;
    await raw.delete('bookmarks');
    await raw.delete('highlights');
    await raw.delete('notes');

    bible = BibleRepository(storage: BibleStorage(rootOverride: tmpDir));
    await bible.init();

    handler = ApiRouter(db: db, bible: bible).handler;
  });

  tearDown(() async {
    bible.dispose();
    await db.close();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<Response> send(
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) =>
      Future.value(handler(Request(
        method,
        Uri.parse('http://192.168.1.42:7777$path'),
        headers: {
          'host': '192.168.1.42:7777',
          if (body != null) 'content-type': 'application/json',
          ...headers,
        },
        body: body == null ? null : jsonEncode(body),
      )));

  /// Reads a response body, un-gzipping it when the handler compressed it.
  Future<dynamic> readJson(Response res) async {
    final bytes = await res.read().expand((c) => c).toList();
    final decoded = res.headers['content-encoding'] == 'gzip'
        ? gzip.decode(bytes)
        : bytes;
    return jsonDecode(utf8.decode(decoded));
  }

  // ── Bible data ────────────────────────────────────────────────────────────

  group('bible data', () {
    test('index lists the active edition and its books', () async {
      final res = await send('GET', '/api/index');
      expect(res.statusCode, 200);

      final body = await readJson(res) as Map<String, dynamic>;
      expect(body['edition']['id'], BibleStorage.bundledEditionId);

      final books = body['books'] as List;
      expect(books, isNotEmpty);
      // USFM ids, not per-edition numbers — the whole point of addressing books
      // by id is that GEN is GEN in every edition.
      expect(books.map((b) => b['id']), contains('GEN'));

      final genesis = books.firstWhere((b) => b['id'] == 'GEN');
      expect(genesis['chapterCount'], 50);
      expect(genesis['nameAm'], isNotEmpty);
      expect(genesis['testament'], isNot('new'));
    });

    test('a chapter carries its verses and their numbers', () async {
      final res = await send('GET', '/api/book/GEN/1');
      expect(res.statusCode, 200);

      final body = await readJson(res) as Map<String, dynamic>;
      expect(body['book']['id'], 'GEN');
      expect(body['chapter']['n'], 1);

      final verses = [
        for (final s in body['chapter']['sections'] as List)
          ...s['verses'] as List,
      ];
      expect(verses.length, greaterThan(25));
      expect(verses.first['verse'], 1);
      expect(verses.first['numbered'], isTrue);
      expect(verses.first['text'], isNotEmpty);
    });

    test('a whole book is served gzipped when the client accepts it', () async {
      final res = await send(
        'GET',
        '/api/book/PSA',
        headers: {'accept-encoding': 'gzip'},
      );
      expect(res.statusCode, 200);
      expect(res.headers['content-encoding'], 'gzip');

      // 151, not 150: the EOTC canon carries Psalm 151.
      final body = await readJson(res) as Map<String, dynamic>;
      expect((body['chapters'] as List).length, 151);
    });

    test('a client that cannot take gzip gets plain bytes', () async {
      final res = await send('GET', '/api/book/JUD');
      expect(res.headers['content-encoding'], isNull);
      expect(await readJson(res), isA<Map<String, dynamic>>());
    });

    test('books can also be named the ways the rest of the app names '
        'them', () async {
      for (final alias in ['GEN', 'Genesis', 'ኦሪት ዘፍጥረት']) {
        final res = await send('GET', '/api/book/${Uri.encodeComponent(alias)}/1');
        expect(res.statusCode, 200, reason: alias);
        expect((await readJson(res) as Map)['book']['id'], 'GEN');
      }
    });

    test('an unknown book is a 404, not a crash', () async {
      final res = await send('GET', '/api/book/NOTABOOK/1');
      expect(res.statusCode, 404);
      expect((await readJson(res) as Map)['error'], isNotEmpty);
    });

    test('a chapter beyond the end of a book is a 404', () async {
      final res = await send('GET', '/api/book/JUD/9');
      expect(res.statusCode, 404);
    });
  });

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  group('bookmarks', () {
    test('round-trips through create, list and delete', () async {
      final created = await send('POST', '/api/bookmarks', body: {
        'bookId': 'GEN',
        'chapter': 1,
        'verseStart': 1,
      });
      expect(created.statusCode, 201);
      final id = (await readJson(created) as Map)['id'] as int;

      final listed = await send('GET', '/api/bookmarks');
      final rows = (await readJson(listed) as Map)['bookmarks'] as List;
      expect(rows, hasLength(1));
      expect(rows.first['bookId'], 'GEN');
      expect(rows.first['verseCount'], 1);

      final deleted = await send('DELETE', '/api/bookmarks/$id');
      expect(deleted.statusCode, 204);

      final after = await send('GET', '/api/bookmarks');
      expect((await readJson(after) as Map)['bookmarks'], isEmpty);
    });

    test('a bookmark written from the browser is visible to the app',
        () async {
      await send('POST', '/api/bookmarks',
          body: {'bookId': 'GEN', 'chapter': 3, 'verseStart': 15});

      // The same AppDatabase the reader screen reads through — no restart, no
      // second connection.
      final inApp = await db.getBookmarks('GEN', 3);
      expect(inApp, hasLength(1));
      expect(inApp.single.verseStart, 15);
      expect(inApp.single.bookNumber, greaterThan(0));
    });

    test('a bookmark on a book this edition lacks is refused', () async {
      final res = await send('POST', '/api/bookmarks',
          body: {'bookId': 'NOTABOOK', 'chapter': 1, 'verseStart': 1});
      expect(res.statusCode, 404);
      expect(await db.getAllBookmarks(), isEmpty);
    });

    test('a malformed reference is a 400', () async {
      expect(
        (await send('POST', '/api/bookmarks', body: {'chapter': 1, 'verseStart': 1}))
            .statusCode,
        400,
      );
      expect(
        (await send('POST', '/api/bookmarks',
                body: {'bookId': 'GEN', 'verseStart': 1}))
            .statusCode,
        400,
      );
      expect(
        (await send('POST', '/api/bookmarks',
                body: {'bookId': 'GEN', 'chapter': 1, 'verseStart': 1, 'verseCount': 0}))
            .statusCode,
        400,
      );
    });

    test('deleting a bookmark that is not there is a 404', () async {
      expect((await send('DELETE', '/api/bookmarks/9999')).statusCode, 404);
    });
  });

  // ── Highlights ────────────────────────────────────────────────────────────

  group('highlights', () {
    test('stores the colour and hands it back as hex', () async {
      final res = await send('POST', '/api/highlights', body: {
        'bookId': 'JHN',
        'chapter': 3,
        'verseStart': 16,
        'color': '#FFE062',
      });
      expect(res.statusCode, 201);
      expect((await readJson(res) as Map)['color'], '#FFE062');

      final stored = await db.getHighlights('JHN', 3);
      expect(stored.single.color.toARGB32(), 0xFFFFE062);
    });

    test('re-highlighting the same verse recolours it rather than stacking',
        () async {
      const ref = {'bookId': 'JHN', 'chapter': 3, 'verseStart': 16};
      await send('POST', '/api/highlights', body: {...ref, 'color': '#FFE062'});
      final second = await send('POST', '/api/highlights',
          body: {...ref, 'color': '#3BAD49'});

      // 200, not 201 — nothing new was created.
      expect(second.statusCode, 200);
      final stored = await db.getHighlights('JHN', 3);
      expect(stored, hasLength(1));
      expect(stored.single.color.toARGB32(), 0xFF3BAD49);
    });

    test('a colour that is not a colour is a 400', () async {
      final res = await send('POST', '/api/highlights', body: {
        'bookId': 'JHN',
        'chapter': 3,
        'verseStart': 16,
        'color': 'burgundy',
      });
      expect(res.statusCode, 400);
      expect(await db.getAllHighlights(), isEmpty);
    });
  });

  // ── Notes ─────────────────────────────────────────────────────────────────

  group('notes', () {
    test('round-trips through create, edit and delete', () async {
      final created = await send('POST', '/api/notes', body: {
        'bookId': 'PSA',
        'chapter': 23,
        'verseStart': 1,
        'content': 'first',
      });
      expect(created.statusCode, 201);
      final id = (await readJson(created) as Map)['id'] as int;

      final patched =
          await send('PATCH', '/api/notes/$id', body: {'content': 'second'});
      expect(patched.statusCode, 200);
      expect((await readJson(patched) as Map)['content'], 'second');
      expect((await db.getNotes('PSA', 23)).single.content, 'second');

      expect((await send('DELETE', '/api/notes/$id')).statusCode, 204);
      expect(await db.getAllNotes(), isEmpty);
    });

    test('an empty note is refused on create and on edit', () async {
      expect(
        (await send('POST', '/api/notes', body: {
          'bookId': 'PSA',
          'chapter': 23,
          'verseStart': 1,
          'content': '   ',
        }))
            .statusCode,
        400,
      );

      final created = await send('POST', '/api/notes', body: {
        'bookId': 'PSA',
        'chapter': 23,
        'verseStart': 1,
        'content': 'kept',
      });
      final id = (await readJson(created) as Map)['id'] as int;

      expect(
        (await send('PATCH', '/api/notes/$id', body: {'content': ''})).statusCode,
        400,
      );
      expect((await db.getNotes('PSA', 23)).single.content, 'kept');
    });
  });

  // ── Static assets ─────────────────────────────────────────────────────────

  group('static assets', () {
    test('the reader page is served at the root', () async {
      final res = await send('GET', '/');
      expect(res.statusCode, 200);
      expect(res.headers['content-type'], startsWith('text/html'));

      final bytes = await res.read().expand((c) => c).toList();
      final html = utf8.decode(res.headers['content-encoding'] == 'gzip'
          ? gzip.decode(bytes)
          : bytes);
      expect(html, contains('<title>መጽሐፍ ቅዱስ</title>'));
      // Fully offline: nothing may be fetched from outside the phone.
      expect(html, isNot(contains('https://')));
    });

    test('every advertised font is actually servable', () async {
      final listed = await send('GET', '/api/fonts');
      final fonts = (await readJson(listed) as Map)['fonts'] as List;
      expect(fonts, hasLength(9));

      for (final f in fonts) {
        for (final file in [f['regular'], if (f['bold'] != null) f['bold']]) {
          final res = await send('GET', '/fonts/$file');
          expect(res.statusCode, 200, reason: '$file');
          expect(res.headers['content-type'], anyOf('font/ttf', 'font/otf'));
          expect(res.headers['cache-control'], contains('max-age'));
        }
      }
    });

    test('the font route cannot be walked out of', () async {
      for (final attempt in [
        '..%2F..%2Fbibles%2Fam-2000.db',
        'not-a-font.ttf',
      ]) {
        expect((await send('GET', '/fonts/$attempt')).statusCode, 404,
            reason: attempt);
      }
      // Nothing outside the allowlist is reachable, however it is spelled.
      expect(kServableFontFiles, hasLength(11));
    });

    test('an unrouted path is a 404 with a JSON body', () async {
      final res = await send('GET', '/api/nope');
      expect(res.statusCode, 404);
      expect((await readJson(res) as Map)['error'], isNotEmpty);
    });
  });

  // ── Server guards ─────────────────────────────────────────────────────────

  group('server guards', () {
    test('only address Hosts are accepted, which is what stops DNS '
        'rebinding', () {
      expect(LocalServerService.isAddressHost('192.168.1.42:7777'), isTrue);
      expect(LocalServerService.isAddressHost('10.0.0.5'), isTrue);
      expect(LocalServerService.isAddressHost('localhost:7777'), isTrue);
      expect(LocalServerService.isAddressHost('[::1]:7777'), isTrue);

      // A hostname is how an attacker's page would reach this server.
      expect(LocalServerService.isAddressHost('evil.example.com'), isFalse);
      expect(LocalServerService.isAddressHost('rebind.attacker.io:7777'),
          isFalse);
    });

    test('a started server answers over a real socket and refuses a '
        'foreign Host', () async {
      final service = LocalServerService();
      try {
        await service.start(db, bible);
      } on LocalServerException catch (e) {
        // A machine with no LAN address (some CI sandboxes) has nothing to
        // serve on; the routes themselves are covered above.
        markTestSkipped('no local network: ${e.reason.name}');
        return;
      }

      addTearDown(service.stop);
      expect(service.isRunning, isTrue);
      expect(service.baseUrl, matches(RegExp(r'^http://[\d.]+:\d+$')));

      // flutter_test installs an HttpOverrides that answers every request with
      // a 400 so unit tests cannot reach the network. This one deliberately
      // talks to a socket on this machine, so the override has to stand down
      // for the duration.
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = overrides);

      final client = HttpClient();
      addTearDown(client.close);

      Future<HttpClientResponse> get(String path, {String? host}) async {
        // Always over the loopback: the point is that the socket is really
        // bound, not that this machine can route to itself by LAN address.
        final req = await client.get('127.0.0.1', service.port!, path);
        if (host != null) req.headers.set('host', host);
        return req.close();
      }

      final page = await get('/');
      expect(page.statusCode, 200);
      expect(await page.transform(utf8.decoder).join(), contains('<title>'));

      final index = await get('/api/index');
      expect(index.statusCode, 200);

      // The DNS-rebinding guard, over the wire.
      final foreign = await get('/api/index', host: 'evil.example.com');
      expect(foreign.statusCode, 403);
      await foreign.drain<void>();

      await service.stop();
      expect(service.isRunning, isFalse);
      expect(service.baseUrl, isNull);
    });

    // Every case here is an address that is private, and therefore looks
    // plausible, but that a browser on the room's WiFi cannot reach.
    group('address picking', () {
      int score(String iface, String ip) =>
          LocalServerService.addressScore(iface, ip);

      void beats(
        ({String iface, String ip}) winner,
        ({String iface, String ip}) loser,
      ) =>
          expect(
            score(winner.iface, winner.ip),
            greaterThan(score(loser.iface, loser.ip)),
            reason: '${winner.iface} ${winner.ip} should beat '
                '${loser.iface} ${loser.ip}',
          );

      test('WiFi beats a VPN tunnel on the same device', () {
        // Mullvad hands out 10.64.0.0/10 — private, and reachable from nobody
        // else on the WiFi.
        beats(
          (iface: 'wlan0', ip: '192.168.1.42'),
          (iface: 'tun0', ip: '10.64.0.1'),
        );
        beats(
          (iface: 'Wi-Fi', ip: '192.168.1.42'),
          (iface: 'Mullvad VPN Tunnel', ip: '10.64.0.1'),
        );
        beats(
          (iface: 'en0', ip: '192.168.1.42'),
          (iface: 'utun3', ip: '10.64.0.1'),
        );
        beats(
          (iface: 'wlan0', ip: '192.168.1.42'),
          (iface: 'wg0', ip: '10.64.0.1'),
        );
      });

      test('WiFi beats mobile data', () {
        beats(
          (iface: 'wlan0', ip: '192.168.1.42'),
          (iface: 'rmnet_data0', ip: '10.183.44.7'),
        );
        beats(
          (iface: 'en0', ip: '192.168.1.42'),
          (iface: 'pdp_ip0', ip: '10.183.44.7'),
        );
      });

      test('WiFi wins even when the carrier address looks more homely', () {
        // The interface has to outrank the range, or a carrier or VPN handing
        // out a 192.168 address would take the URL.
        beats(
          (iface: 'wlan0', ip: '10.0.0.9'),
          (iface: 'rmnet_data0', ip: '192.168.8.1'),
        );
        beats(
          (iface: 'wlan0', ip: '10.0.0.9'),
          (iface: 'docker0', ip: '192.168.99.1'),
        );
      });

      test('real networks beat virtual adapters on desktop', () {
        beats(
          (iface: 'Wi-Fi', ip: '192.168.1.42'),
          (iface: 'VMware Network Adapter VMnet1', ip: '192.168.220.1'),
        );
        beats(
          (iface: 'Ethernet', ip: '192.168.1.42'),
          (iface: 'vEthernet (Default Switch)', ip: '172.20.0.1'),
        );
        beats(
          (iface: 'wlp3s0', ip: '192.168.1.42'),
          (iface: 'br-1a2b3c', ip: '172.18.0.1'),
        );
      });

      test('among equals the homeliest range wins', () {
        beats(
          (iface: 'wlan0', ip: '192.168.1.42'),
          (iface: 'wlan1', ip: '10.0.0.9'),
        );
        beats(
          (iface: 'wlan0', ip: '172.16.4.4'),
          (iface: 'wlan1', ip: '10.0.0.9'),
        );
        // Carrier-grade NAT is not a LAN.
        beats(
          (iface: 'wlan0', ip: '10.0.0.9'),
          (iface: 'wlan1', ip: '100.64.1.1'),
        );
      });

      test('a hotspot the phone is itself hosting still counts as WiFi', () {
        beats(
          (iface: 'ap0', ip: '192.168.43.1'),
          (iface: 'rmnet_data0', ip: '10.183.44.7'),
        );
      });
    });

    test('private ranges are preferred over routable ones', () {
      expect(LocalServerService.isPrivateAddress('192.168.0.7'), isTrue);
      expect(LocalServerService.isPrivateAddress('10.1.2.3'), isTrue);
      expect(LocalServerService.isPrivateAddress('172.16.0.1'), isTrue);
      expect(LocalServerService.isPrivateAddress('172.31.255.254'), isTrue);

      expect(LocalServerService.isPrivateAddress('172.15.0.1'), isFalse);
      expect(LocalServerService.isPrivateAddress('172.32.0.1'), isFalse);
      expect(LocalServerService.isPrivateAddress('8.8.8.8'), isFalse);
    });
  });
}
