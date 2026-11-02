import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../features/books/data/repositories/bible_repository.dart';
import '../storage/app_database.dart';
import 'api_router.dart';
import 'foreground_service.dart';

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

  /// Keeps the process alive and reachable once the app is backgrounded.
  /// Injectable so tests can drive the server without a platform channel.
  final WebReaderForegroundService foreground;

  LocalServerService({
    this.foreground = const WebReaderForegroundService(),
  });

  HttpServer? _server;

  /// Bumped by every [stop]. A [start] that was in flight when the app went to
  /// the background finds its generation stale and closes the socket it just
  /// opened, rather than leaving a server running that nothing will stop.
  int _generation = 0;

  String? _localIp;
  String? _localInterface;
  int? _boundPort;

  /// The device's LAN address, null while the server is stopped.
  String? get localIp => _localIp;

  /// The interface [localIp] was taken from — `wlan0`, `Wi-Fi`, `en0`. Shown
  /// beside the address so that when the wrong network wins, the user can see
  /// which one did.
  String? get localInterface => _localInterface;

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
  Future<String> start(
    AppDatabase db,
    BibleRepository bible, {
    String foregroundTitle = 'Local Web Reader',
    String foregroundStopLabel = 'Stop',
  }) async {
    if (_server != null) return baseUrl!;
    final generation = _generation;

    final found = await _findLocalIp();
    if (found == null) {
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
    _localIp = found.ip;
    _localInterface = found.interfaceName;
    _boundPort = bound.port;
    debugPrint('[WebReader] serving on $baseUrl (${found.interfaceName})');

    // Only now: a notification saying the Bible is being served, raised before
    // the socket was listening, would be false for as long as binding took.
    await foreground.start(
      title: foregroundTitle,
      url: baseUrl!,
      stopLabel: foregroundStopLabel,
    );
    return baseUrl!;
  }

  /// Stops the server and releases the port. Safe to call when not running.
  Future<void> stop() async {
    _generation++;
    final server = _server;
    _server = null;
    _localIp = null;
    _localInterface = null;
    _boundPort = null;
    // Unconditional: a cancelled start may have raised the notification even
    // though no server was ever assigned.
    await foreground.stop();
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

  /// The device's address on the local network, and the interface it is on.
  ///
  /// Read straight from `dart:io` rather than through a WiFi plugin: this needs
  /// no Android permission beyond the ones the app already has, works when the
  /// device is on Ethernet or a tethered hotspot rather than WiFi, and works on
  /// desktop, where a WiFi plugin has nothing to report.
  ///
  /// Every candidate is scored rather than taking the first private address:
  /// "private" is not the same as "reachable from the laptop in the room". A
  /// phone with mobile data on has a carrier address on `rmnet_data0`, and a
  /// VPN client hands out one of its own — Mullvad's is 10.64.0.0/10 — and both
  /// look exactly as private as the WiFi address while being reachable from
  /// nowhere the user cares about.
  static Future<({String ip, String interfaceName})?> _findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );

      ({String ip, String interfaceName, int score})? best;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          // 169.254.x.x means DHCP failed; the address exists but nothing else
          // on the network can be reached at it.
          if (ip.startsWith('169.254.')) continue;

          final score = addressScore(iface.name, ip);
          // Logged for every candidate, not only the winner: when the address
          // on the card is not the one the user expected, this is what says
          // which interfaces were on offer and why one of them won.
          debugPrint('[WebReader] candidate ${iface.name} $ip (score $score)');
          if (best == null || score > best.score) {
            best = (ip: ip, interfaceName: iface.name, score: score);
          }
        }
      }
      if (best == null) return null;
      return (ip: best.ip, interfaceName: best.interfaceName);
    } on Object catch (e) {
      debugPrint('[WebReader] could not list interfaces: $e');
      return null;
    }
  }

  /// How likely an address is to be the one a browser on the same WiFi can
  /// reach. Higher wins; the interface matters more than the range.
  @visibleForTesting
  static int addressScore(String interfaceName, String ip) =>
      _interfaceRank(interfaceName) * 10 + _rangeRank(ip);

  static int _interfaceRank(String rawName) {
    final name = rawName.toLowerCase();

    bool startsWithAny(List<String> prefixes) =>
        prefixes.any(name.startsWith);

    // Cellular. A carrier address is private and useless here: it is reachable
    // from inside the carrier's network, never from the laptop on the WiFi.
    if (startsWithAny(const [
      'rmnet', 'pdp_ip', 'ccmni', 'ccinet', 'seth_', 'clat', 'v4-rmnet',
    ])) {
      return 0;
    }

    // Tunnels and virtual adapters — VPN clients, containers, VM host-only
    // networks. All hand out real private addresses on networks the browser is
    // not on.
    if (startsWithAny(const [
          'tun', 'tap', 'utun', 'ppp', 'wg', 'nordlynx', 'ipsec', 'zt',
          'docker', 'veth', 'br-', 'virbr', 'vboxnet', 'vmnet', 'vethernet',
        ]) ||
        name.contains('virtual') ||
        name.contains('vpn') ||
        name.contains('tailscale') ||
        name.contains('hyper-v') ||
        name.contains('loopback')) {
      return 1;
    }

    // WiFi, including the phone's own hotspot — the case this feature is for.
    if (startsWithAny(const ['wlan', 'wlp', 'wl', 'ap', 'airport']) ||
        name.contains('wi-fi') ||
        name.contains('wifi') ||
        name.contains('wireless')) {
      return 4;
    }

    // Wired. Still the same LAN as the WiFi in almost every home.
    if (startsWithAny(const ['eth', 'en', 'em', 'eno', 'ens', 'enp'])) {
      return 3;
    }

    return 2;
  }

  /// Prefers the ranges a home or office router actually hands out. 192.168/16
  /// is overwhelmingly the common case; 10/8 is last because it is also where
  /// carriers and VPNs live.
  static int _rangeRank(String ip) {
    if (ip.startsWith('192.168.')) return 3;
    if (_is172Private(ip)) return 2;
    if (ip.startsWith('10.')) return 1;
    // Routable, or carrier-grade NAT (100.64/10).
    return 0;
  }

  /// RFC 1918 ranges, which is what a home or office router hands out.
  @visibleForTesting
  static bool isPrivateAddress(String ip) => _isPrivate(ip);

  static bool _isPrivate(String ip) =>
      ip.startsWith('192.168.') || ip.startsWith('10.') || _is172Private(ip);

  /// 172.16.0.0 – 172.31.255.255.
  static bool _is172Private(String ip) {
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
