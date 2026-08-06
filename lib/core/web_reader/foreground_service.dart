import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Android foreground service that keeps the Local Web Reader answering
/// once the app is off the screen.
///
/// A backgrounded Android process is frozen or killed at the system's
/// convenience and loses network access in Doze, so without this the server
/// stops working a few minutes after the screen goes off — which is exactly
/// when someone is reading on their laptop with the phone face down.
///
/// A no-op everywhere else. iOS suspends a backgrounded app outright and will
/// not keep a socket server alive for this; desktop needs no help. On those
/// platforms the server runs for as long as the app does, which is what the
/// platform allows.
class WebReaderForegroundService {
  const WebReaderForegroundService();

  static const _channel = MethodChannel('eotcbible/web_reader');

  /// True where a foreground service is both possible and needed.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Shows the ongoing notification and pins the process in the foreground.
  ///
  /// [title], [url] and [stopLabel] are already localized by the caller — the
  /// service has no access to the app's strings.
  Future<void> start({
    required String title,
    required String url,
    required String stopLabel,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('startForeground', {
        'title': title,
        'url': url,
        'stopLabel': stopLabel,
      });
    } on PlatformException catch (e) {
      // The server is already listening; losing the notification makes it
      // fragile in the background, not broken.
      debugPrint('[WebReader] foreground service refused to start: ${e.message}');
    } on MissingPluginException {
      debugPrint('[WebReader] foreground service channel not registered');
    }
  }

  Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('stopForeground');
    } on PlatformException catch (e) {
      debugPrint('[WebReader] foreground service refused to stop: ${e.message}');
    } on MissingPluginException {
      // Nothing was ever started.
    }
  }

  /// Called when the user taps Stop on the notification.
  ///
  /// The service can only take its own notification down; the socket lives on
  /// the Dart side, so the tap has to come back here to actually close it.
  void onStopRequested(Future<void> Function() handler) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopRequested') await handler();
      return null;
    });
  }
}
