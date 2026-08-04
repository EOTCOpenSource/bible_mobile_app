import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../features/books/data/repositories/bible_repository.dart';
import '../storage/app_database.dart';
import 'api_router.dart';

/// Runs the Local Web Reader's HTTP server on the device.
///
/// Bound to [InternetAddress.anyIPv4] so anything on the same WiFi can reach
/// it, and never further: a home router's NAT does not forward inbound
/// connections, so the server is unreachable from the internet without the user
/// having deliberately opened a port. Nothing it serves is a credential — the
/// user's own scripture and annotations, on their own network — so there is no
/// login, which is what makes "tap once, type the URL on the laptop" work.
///
/// The server is stopped whenever the app leaves the foreground, so starting it
/// is always a deliberate act and the port is never held by a backgrounded app.
class LocalServerService {
  /// The port the URL is advertised on. Nothing else in the Flutter ecosystem
  /// claims it, and keeping it fixed means the address the user typed yesterday
  /// still works today.
  static const defaultPort = 7777;

  /// Ports are tried in order from [defaultPort]; another app holding 7777
  /// should degrade to a different URL, not to a dead button.
  static const _portAttempts = 8;

  HttpServer? _server;

  /// Bumped by every [stop]. A [start] that was in flight when the app went to
  /// the background finds its generation stale and closes the socket it just
  /// opened, rather than leaving a server running that nothing will stop.
  int _generation = 0;

  String? _localIp;
  int? _boundPort;

  /// The device's LAN address, null while the server is stopped.
  String? get localIp => _localIp;

  /// The port actually bound, which is [defaultPort] unless it was taken.
  int? get port => _boundPort;

  bool get isRunning => _server != null;

  /// `http://192.168.1.42:7777`, or null while stopped.
  String? get baseUrl {
    final ip = _localIp;
    final p = _boundPort;
    return (ip == null || p == null) ? null : 'http://$ip:$p';
  }

  /// Starts the server and returns its base URL.
  ///
  /// Throws [LocalServerException] when the device has no usable LAN address
  /// (WiFi off, or on a network that gave out none) or when every candidate
  /// port is taken — both are conditions the card reports to the user rather
  /// than states worth crashing over.
  Future<String> start(AppDatabase db, BibleRepository bible) async {
    if (_server != null) return baseUrl!;
    final generation = _generation;

    final ip = await _findLocalIp();
    if (ip == null) {
      throw const LocalServerException(LocalServerError.noNetwork);
    }

    final api = ApiRouter(db: db, bible: bible);
    final handler = const Pipeline()
        .addMiddleware(_rejectForeignHosts)
        .addMiddleware(_rateLimit())
        .addMiddleware(_logRequests)
        .addHandler(api.handler);

    HttpServer? bound;
    for (var i = 0; i < _portAttempts; i++) {
      final candidate = defaultPort + i;
      try {
        bound = await shelf_io.serve(
          handler,
          InternetAddress.anyIPv4,
          candidate,
          shared: false,
        );
        break;
      } on SocketException catch (e) {
        debugPrint('[WebReader] port $candidate unavailable: ${e.message}');
      }
    }
    if (bound == null) {
      throw const LocalServerException(LocalServerError.noFreePort);
    }

    // A stop landed while this start was binding — honour it.
    if (generation != _generation) {
      await bound.close(force: true);
      throw const LocalServerException(LocalServerError.cancelled);
    }

    // Chunked transfer is the wrong default here: responses are built whole in
    // memory anyway, and a known Content-Length lets the browser show progress
    // on the larger book payloads.
    bound.autoCompress = false;

    _server = bound;
    _localIp = ip;
    _boundPort = bound.port;
    debugPrint('[WebReader] serving on $baseUrl');
    return baseUrl!;
  }

  /// Stops the server and releases the port. Safe to call when not running.
  Future<void> stop() async {
    _generation++;
    final server = _server;
    _server = null;
    _localIp = null;
    _boundPort = null;
    if (server == null) return;
    try {
      // `force` so a browser holding a keep-alive connection open cannot keep
      // the port — the app is usually being backgrounded when this runs.
      await server.close(force: true);
      debugPrint('[WebReader] stopped');
    } on Object catch (e) {
      debugPrint('[WebReader] stop failed: $e');
    }
  }

  // ── Address discovery ─────────────────────────────────────────────────────

  /// The device's address on the local network.
  ///
  /// Read straight from `dart:io` rather than through a WiFi plugin: this needs
  /// no Android permission beyond the ones the app already has, works when the
  /// device is on Ethernet or a tethered hotspot rather than WiFi, and works on
  /// desktop, where a WiFi plugin has nothing to report.
  static Future<String?> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );

      String? fallback;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          // 169.254.x.x means DHCP failed; the address exists but nothing else
          // on the network can be reached at it.
          if (ip.startsWith('169.254.')) continue;
          if (_isPrivate(ip)) return ip;
          fallback ??= ip;
        }
      }
      // A non-private address is unusual but not wrong — some networks hand out
      // routable addresses directly — so it beats reporting no network at all.
      return fallback;
    } on Object catch (e) {
      debugPrint('[WebReader] could not list interfaces: $e');
      return null;
    }
  }

  /// RFC 1918 ranges, which is what a home or office router hands out.
  @visibleForTesting
  static bool isPrivateAddress(String ip) => _isPrivate(ip);

  static bool _isPrivate(String ip) {
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    if (!ip.startsWith('172.')) return false;
    final second = int.tryParse(ip.split('.').elementAtOrNull(1) ?? '');
    return second != null && second >= 16 && second <= 31;
  }

  // ── Middleware ────────────────────────────────────────────────────────────

  /// Refuses requests whose `Host` is a name rather than an address.
  ///
  /// This is the DNS-rebinding guard. Without it, any web page the user visits
  /// could point its own hostname at this device's LAN address and then read
  /// and rewrite their annotations from the browser, because the browser would
  /// treat that as same-origin with the attacker's script. A real reader always
  /// arrives by typing the IP, so requiring the `Host` to *be* that address
  /// costs nothing and closes the hole.
  static Handler _rejectForeignHosts(Handler inner) => (request) {
        final host = request.headers['host'];
        if (host != null && !_isAddressHost(host)) {
          debugPrint('[WebReader] rejected Host: $host');
          return Response.forbidden(
            'Open this page by its IP address.',
          );
        }
        return inner(request);
      };

  @visibleForTesting
  static bool isAddressHost(String host) => _isAddressHost(host);

  static bool _isAddressHost(String host) {
    // Strip the port; IPv6 literals arrive bracketed.
    var name = host;
    if (name.startsWith('[')) {
      final close = name.indexOf(']');
      if (close > 0) name = name.substring(1, close);
    } else if (name.contains(':')) {
      name = name.substring(0, name.lastIndexOf(':'));
    }
    if (name == 'localhost') return true;
    return InternetAddress.tryParse(name) != null;
  }

  /// A token bucket capped at [_burst], refilling at [_perSecond] tokens a
  /// second.
  ///
  /// A page load asks for the index, a chapter, three annotation lists and a
  /// font all at once, so a flat per-second cap would trip on ordinary use —
  /// the burst allowance is what makes the limit a runaway-tab guard rather
  /// than a throttle on the reader.
  static Middleware _rateLimit() {
    const perSecond = 60.0;
    const burst = 120.0;
    var tokens = burst;
    var last = DateTime.now();

    return (inner) => (request) {
          final now = DateTime.now();
          final elapsed = now.difference(last).inMicroseconds / 1e6;
          last = now;
          tokens = (tokens + elapsed * perSecond).clamp(0.0, burst);

          if (tokens < 1) {
            return Response(429, body: 'Too many requests', headers: {
              'retry-after': '1',
            });
          }
          tokens -= 1;
          return inner(request);
        };
  }

  static Handler _logRequests(Handler inner) => (request) async {
        final response = await inner(request);
        if (response.statusCode >= 400) {
          debugPrint('[WebReader] ${response.statusCode} '
              '${request.method} /${request.url.path}');
        }
        return response;
      };
}

enum LocalServerError {
  /// No usable LAN address — WiFi is off, or the network gave out none.
  noNetwork,

  /// Every candidate port was already taken.
  noFreePort,

  /// A stop arrived while the start was still binding — the app went to the
  /// background mid-tap. Not shown to the user; the card is simply off.
  cancelled,
}

class LocalServerException implements Exception {
  const LocalServerException(this.reason);

  final LocalServerError reason;

  @override
  String toString() => 'LocalServerException(${reason.name})';
}
