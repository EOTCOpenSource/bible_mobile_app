import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kenat/kenat.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../settings/app_settings.dart';
import '../deep_links/deep_link_uri.dart';
import '../../features/books/data/repositories/bible_repository.dart';
import '../../features/books/presentation/pages/reader_screen.dart';

/// Centralized notification configuration.
/// Prevents magic numbers and ensures consistency across the app.
class NotificationConfig {
  static const int dailyVerseId = 1;
  static const int readingReminderId = 2;
  static const String dailyVerseChannel = 'daily_verse_channel';
  static const String readingReminderChannel = 'reading_reminder_channel';
  static const String channelGroupDaily = 'daily_reminders';

  static const String defaultDailyVerseTitle = ' የዕለቱ ጥቅስ';
  static const String defaultReadingReminderTitle = ' ዛሬ አነብ';
  static const String defaultReadingReminderBody =
      'Open the app and read today.';

  static const Duration permissionCacheDuration = Duration(hours: 24);

  /// Rotating list of Amharic motivational phrases used for the reading
  /// reminder body. The phrase is chosen by day-of-year so it changes
  /// daily but never randomly (consistent across restarts).
  static const List<String> motivationalPhrases = [
    'ቃሉ ለዕለቴ ብርሃን ነው። ዛሬ ቀጥል።',
    
  ];

  /// Returns a motivational phrase for [date] based on day-of-year.
  static String motivationalPhraseFor(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return motivationalPhrases[dayOfYear % motivationalPhrases.length];
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingPayload;
  late final BibleRepository _repository;
  bool _initialized = false;

  // Permission caching to avoid repeated permission requests
  bool? _permissionsCached;
  DateTime? _permissionsCachedAt;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
  set navigatorKey(GlobalKey<NavigatorState>? value) {
    _navigatorKey = value;
    if (_pendingPayload != null && _navigatorKey != null) {
      unawaited(_handlePayload(_pendingPayload!));
      _pendingPayload = null;
    }
  }

  /// Initialize the notification service.
  /// Must be called in main() before runApp().
  /// Sets up timezone, initializes the plugin, and handles launch notifications.
  Future<void> init({
    required BibleRepository repository,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    try {
      _repository = repository;
      this.navigatorKey = navigatorKey;

      await _configureLocalTimeZone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          if (_navigatorKey == null) {
            _pendingPayload = payload;
            debugPrint(
              '[NotificationService] Notification launch payload queued (navigator not ready): $payload',
            );
          } else {
            unawaited(_handlePayload(payload));
          }
        }
      }

      _initialized = true;
      debugPrint('[NotificationService] Initialization complete');
    } catch (e, st) {
      debugPrint('[NotificationService] Error during init: $e\n$st');
      rethrow;
    }
  }

  /// Configure the device's local timezone.
  /// Falls back to UTC if timezone detection fails.
  Future<void> _configureLocalTimeZone() async {
    try {
      tz.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      debugPrint('[NotificationService] Timezone configured: ${localTimezone.identifier}');
    } catch (e) {
      debugPrint(
        '[NotificationService] Timezone detection failed, using UTC: $e',
      );
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Request notification permissions from the user.
  /// Caches the result for [NotificationConfig.permissionCacheDuration].
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      // Return cached result if recent
      if (_permissionsCached != null && _permissionsCachedAt != null) {
        final elapsed = DateTime.now().difference(_permissionsCachedAt!);
        if (elapsed < NotificationConfig.permissionCacheDuration) {
          debugPrint(
            '[NotificationService] Using cached permission state: $_permissionsCached',
          );
          return _permissionsCached!;
        }
      }

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final androidGranted =
          await androidPlugin?.requestNotificationsPermission() ?? true;
      final exactAlarmsGranted =
          await androidPlugin?.requestExactAlarmsPermission() ?? true;

      final iosGranted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;

      final macGranted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;

      final granted =
          androidGranted && exactAlarmsGranted && iosGranted && macGranted;

      // Cache the result
      _permissionsCached = granted;
      _permissionsCachedAt = DateTime.now();

      debugPrint(
        '[NotificationService] Permission request: android=$androidGranted '
        'exactAlarms=$exactAlarmsGranted ios=$iosGranted macos=$macGranted → $granted',
      );

      return granted;
    } catch (e, st) {
      debugPrint('[NotificationService] Error requesting permissions: $e\n$st');
      // Assume true to allow retry, but log the error
      return true;
    }
  }

  /// Invalidate cached permission state.
  /// Call this after a settings change that might require re-requesting permissions.
  void invalidatePermissionCache() {
    _permissionsCached = null;
    _permissionsCachedAt = null;
    debugPrint('[NotificationService] Permission cache invalidated');
  }

  /// Cancel a notification by ID.
  /// Safe to call even if notification doesn't exist.
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
      debugPrint('[NotificationService] Cancelled notification id=$id');
    } catch (e, st) {
      debugPrint(
        '[NotificationService] Error cancelling notification id=$id: $e\n$st',
      );
    }
  }

  /// Schedule a daily notification at `time`.
  /// Always cancels any existing notification with the same ID first to prevent duplicates.
  /// Uses exact alarms to ensure it fires even in Doze mode.
  /// Matches by time only, so it repeats every day at the same time.
  Future<void> scheduleDailyAt(
    int id,
    TimeOfDay time,
    String title,
    String body, {
    String? payload,
    String? channelId,
  }) async {
    try {
      if (!_initialized) {
        debugPrint(
          '[NotificationService] Attempted to schedule before initialization',
        );
        return;
      }

      // Always cancel first to prevent duplicates
      await cancel(id);

      final scheduledDate = _nextInstanceOf(time);
      final androidDetails = AndroidNotificationDetails(
        channelId ?? NotificationConfig.dailyVerseChannel,
        'Daily reminders',
        channelDescription: 'Daily verse and reading time reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'ticker',
        groupKey: NotificationConfig.channelGroupDaily,
      );
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'daily_notifications',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint(
        '[NotificationService] Scheduled notification id=$id at '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} '
        'payload=$payload',
      );
    } catch (e, st) {
      debugPrint(
        '[NotificationService] Error scheduling notification id=$id: $e\n$st',
      );
      rethrow;
    }
  }

  /// Schedule a daily verse notification.
  /// Loads today's verse from BibleRepository and includes it in the body.
  /// The body includes the reference + a truncated verse preview for
  /// engagement (≤ 120 chars so it renders fully on the lock screen).
  /// Always cancels any existing daily verse notification first.
  Future<void> scheduleDailyVerse(TimeOfDay time, String title) async {
    try {
      debugPrint(
        '[NotificationService] Scheduling daily verse at ${time.hour}:${time.minute}',
      );

      final et = Kenat.now().getEthiopian();
      final month = et['month'] as int;
      final day = et['day'] as int;

      final result = await _repository.loadDailyVerse(month, day);
      if (result == null) {
        debugPrint(
          '[NotificationService] Daily verse not found for $month/$day, using fallback',
        );
        await scheduleDailyAt(
          NotificationConfig.dailyVerseId,
          time,
          title,
          'ቀኑን ቃሉን ያንብቡ',
          payload: 'home',
          channelId: NotificationConfig.dailyVerseChannel,
        );
        return;
      }

      final reference =
          '${result.bookNameAm} ${result.chapter}:${result.verse}';

      // Build a rich preview: "Reference — first N chars of verse"
      final preview = result.text.length > 100
          ? '${result.text.substring(0, 100)}…'
          : result.text;
      final body = '$reference\n$preview';

      final payload = Uri(
        scheme: 'eotcbible',
        host: 'openinapp',
        path:
            '/${verseDeepLinkSlug(result.bookEntry, result.chapter, result.verse)}',
      ).toString();

      await scheduleDailyAt(
        NotificationConfig.dailyVerseId,
        time,
        title,
        body,
        payload: payload,
        channelId: NotificationConfig.dailyVerseChannel,
      );
      debugPrint('[NotificationService] Daily verse scheduled: $reference');
    } catch (e, st) {
      debugPrint('[NotificationService] Error scheduling daily verse: $e\n$st');
      rethrow;
    }
  }

  /// Schedule a reading time reminder notification.
  /// The body rotates through [NotificationConfig.motivationalPhrases]
  /// using today's date so the text is fresh each day.
  /// Always cancels any existing reading reminder notification first.
  Future<void> scheduleReadingReminder(TimeOfDay time, String title) async {
    try {
      debugPrint(
        '[NotificationService] Scheduling reading reminder at ${time.hour}:${time.minute}',
      );

      final body = NotificationConfig.motivationalPhraseFor(DateTime.now());

      await scheduleDailyAt(
        NotificationConfig.readingReminderId,
        time,
        title,
        body,
        payload: 'home',
        channelId: NotificationConfig.readingReminderChannel,
      );
      debugPrint('[NotificationService] Reading reminder scheduled');
    } catch (e, st) {
      debugPrint(
        '[NotificationService] Error scheduling reading reminder: $e\n$st',
      );
      rethrow;
    }
  }

  /// Restore all scheduled notifications based on AppSettings.
  /// Call this after reading settings (e.g., on app startup).
  /// Prevents duplicate scheduling by always canceling first.
  Future<void> restoreScheduledNotifications(AppSettings settings) async {
    try {
      debugPrint('[NotificationService] Restoring notifications from settings');

      // Restore daily verse notification
      if (settings.dailyVerseNotificationEnabled) {
        final time =
            settings.dailyVerseNotificationTime ??
            const TimeOfDay(hour: 6, minute: 0);
        await scheduleDailyVerse(
          time,
          NotificationConfig.defaultDailyVerseTitle,
        );
      } else {
        await cancel(NotificationConfig.dailyVerseId);
      }

      // Restore reading time notification
      if (settings.readingTimeNotificationEnabled) {
        final reminderTime =
            settings.readingTimeNotificationTime ??
            const TimeOfDay(hour: 20, minute: 0);
        await scheduleReadingReminder(
          reminderTime,
          NotificationConfig.defaultReadingReminderTitle,
        );
      } else {
        await cancel(NotificationConfig.readingReminderId);
      }

      debugPrint('[NotificationService] Notifications restored');
    } catch (e, st) {
      debugPrint(
        '[NotificationService] Error restoring notifications: $e\n$st',
      );
      // Don't rethrow - allow app to continue even if restore fails
    }
  }

  /// Calculate the next occurrence of `time` from now.
  /// If `time` has already passed today, schedule for tomorrow.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Handle notification response (when user taps a notification).
  /// This is called both when the app is running and when launched from terminated state.
  void _onNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) {
        debugPrint(
          '[NotificationService] Notification tapped with empty payload',
        );
        _navigateHome();
        return;
      }
      debugPrint(
        '[NotificationService] Notification tapped with payload: $payload',
      );
      unawaited(_handlePayload(payload));
    } catch (e, st) {
      debugPrint(
        '[NotificationService] Error handling notification response: $e\n$st',
      );
      _navigateHome();
    }
  }

  /// Navigate to the target based on the notification payload.
  /// Payloads:
  /// - `'home'` → navigate to home screen
  /// - `'eotcbible://openinapp/{slug}'` → deep link to verse
  ///
  /// Navigation is deferred via [SchedulerBinding.addPostFrameCallback] so it
  /// is safe to call even when the app was just launched from a terminated
  /// state (the navigator widget tree may not have been built yet).
  /// Falls back to home screen if parsing / navigation fails.
  Future<void> _handlePayload(String payload) async {
    try {
      if (payload == 'home') {
        _navigateHomeDeferred();
        return;
      }

      // Attempt to parse as deep link and navigate to verse
      try {
        final uri = Uri.parse(payload);
        final index = await _repository.loadIndex();
        final target = parseDeepLink(uri, index);
        if (target != null) {
          _navigateReaderDeferred(target);
          return;
        }
      } catch (e) {
        debugPrint('[NotificationService] Failed to parse deep link: $e');
      }

      // Fallback to home if parsing/navigation fails
      _navigateHomeDeferred();
    } catch (e, st) {
      debugPrint('[NotificationService] Error handling payload: $e\n$st');
      _navigateHomeDeferred();
    }
  }

  /// Defers [_navigateHome] to the next frame so the navigator is guaranteed
  /// to be ready even when the app launches from a terminated state.
  void _navigateHomeDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _navigateHome());
  }

  /// Defers [_navigatorPushReader] to the next frame.
  void _navigateReaderDeferred(DeepLinkTarget target) {
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _navigatorPushReader(target));
  }

  /// Navigate to home screen.
  /// Pops all routes to return to the home screen.
  /// Safe to call even if navigator is not yet available.
  void _navigateHome() {
    try {
      final state = navigatorKey?.currentState;
      if (state == null) {
        debugPrint(
          '[NotificationService] Navigator not available, cannot navigate home',
        );
        return;
      }
      state.popUntil((route) => route.isFirst);
      debugPrint('[NotificationService] Navigated to home');
    } catch (e, st) {
      debugPrint('[NotificationService] Error navigating home: $e\n$st');
    }
  }

  /// Navigate to reader screen with a specific verse.
  /// Safe to call even if navigator is not yet available.
  void _navigatorPushReader(DeepLinkTarget target) {
    try {
      final state = navigatorKey?.currentState;
      if (state == null) {
        debugPrint(
          '[NotificationService] Navigator not available, cannot open reader',
        );
        return;
      }
      state.push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            entry: target.entry,
            initialChapterNumber: target.chapter,
            initialVerse: target.verse,
          ),
        ),
      );
      debugPrint(
        '[NotificationService] Navigated to reader: '
        '${target.entry.bookNameEn} ${target.chapter}:${target.verse}',
      );
    } catch (e, st) {
      debugPrint('[NotificationService] Error navigating to reader: $e\n$st');
      _navigateHome();
    }
  }
}
