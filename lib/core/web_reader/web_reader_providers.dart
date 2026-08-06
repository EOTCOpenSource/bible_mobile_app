import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bible_repository_provider.dart';
import '../storage/app_database_provider.dart';
import 'local_server_service.dart';

/// What the Local Web Reader card shows.
@immutable
class WebReaderState {
  const WebReaderState({
    this.url,
    this.interfaceName,
    this.isBusy = false,
    this.error,
  });

  /// `http://192.168.1.42:7777` while running, null while stopped.
  final String? url;

  /// The network interface the address came from — `wlan0`, `Wi-Fi`. Shown
  /// beside the URL so a phone that picked its VPN or mobile-data address
  /// says so instead of just looking wrong.
  final String? interfaceName;

  /// A start or stop is in flight — the button is disabled meanwhile so a
  /// double tap cannot leave a server running with no way to stop it.
  final bool isBusy;

  /// Why the last start failed, cleared by the next attempt.
  final LocalServerError? error;

  bool get isRunning => url != null;

  WebReaderState copyWith({
    String? url,
    String? interfaceName,
    bool? isBusy,
    LocalServerError? error,
    bool clearUrl = false,
    bool clearError = false,
  }) =>
      WebReaderState(
        url: clearUrl ? null : (url ?? this.url),
        interfaceName:
            clearUrl ? null : (interfaceName ?? this.interfaceName),
        isBusy: isBusy ?? this.isBusy,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Starts and stops [LocalServerService], and holds the URL the card shows.
class WebReaderNotifier extends StateNotifier<WebReaderState> {
  WebReaderNotifier(this._ref, this._server) : super(const WebReaderState()) {
    // Stop tapped on the foreground-service notification. The socket lives
    // here, not in the service, so the tap has to come back to Dart.
    _server.foreground.onStopRequested(() async {
      await _server.stop();
      if (mounted) state = const WebReaderState();
    });
  }

  final Ref _ref;
  final LocalServerService _server;

  /// Starts the server.
  ///
  /// [notificationTitle] and [stopLabel] are handed in already localized —
  /// this notifier has no [BuildContext], and the Android service has no
  /// access to the app's strings at all.
  Future<void> start({
    required String notificationTitle,
    required String stopLabel,
  }) async {
    if (state.isBusy || state.isRunning) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final url = await _server.start(
        _ref.read(appDatabaseProvider),
        _ref.read(bibleRepositoryProvider),
        foregroundTitle: notificationTitle,
        foregroundStopLabel: stopLabel,
      );
      state = WebReaderState(
        url: url,
        interfaceName: _server.localInterface,
      );
    } on LocalServerException catch (e) {
      // A cancelled start is the lifecycle observer doing its job, not a
      // failure to report — the card just stays off.
      state = e.reason == LocalServerError.cancelled
          ? const WebReaderState()
          : WebReaderState(error: e.reason);
    } on Object catch (e) {
      debugPrint('[WebReader] start failed: $e');
      state = const WebReaderState(error: LocalServerError.noNetwork);
    }
  }

  Future<void> stop() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true);
    await _server.stop();
    state = const WebReaderState();
  }

  /// Stops the server because the app itself is going away.
  ///
  /// Called only for [AppLifecycleState.detached] — the process is ending, so
  /// the socket and the notification have to go with it. Merely backgrounding
  /// the app deliberately does *not* come through here: reading on a laptop
  /// while the phone sits face down on the desk is the whole point, and the
  /// Android foreground service exists to keep that working.
  ///
  /// Does not consult [state]: a start still binding when the app is torn down
  /// needs cancelling just as much as a running one.
  Future<void> stopForLifecycle() async {
    await _server.stop();
    if (mounted) state = const WebReaderState();
  }
}

/// One server per app. A `Provider` rather than an `autoDispose` one: the
/// server outlives the Me screen that started it, and must not be torn down
/// just because the user navigated away from the card.
final localServerServiceProvider =
    Provider<LocalServerService>((_) => LocalServerService());

final webReaderProvider =
    StateNotifierProvider<WebReaderNotifier, WebReaderState>(
  (ref) => WebReaderNotifier(ref, ref.watch(localServerServiceProvider)),
);
