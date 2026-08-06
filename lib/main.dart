import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/deep_links/deep_link_uri.dart';
import 'core/l10n/l10n.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/bible_repository_provider.dart';
import 'core/services/repository_provider.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_provider.dart';
import 'core/storage/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/web_reader/web_reader_providers.dart';
import 'features/books/data/repositories/bible_repository.dart';
import 'features/books/presentation/pages/reader_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/onboarding/presentation/pages/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bibleRepository = BibleRepository();

  // Unpacks the bundled catalog and am-2000 database on first launch and opens
  // the last-used edition. Everything that reads scripture depends on this, so
  // it blocks startup rather than racing the first frame.
  await bibleRepository.init();

  await NotificationService.instance.init(repository: bibleRepository);
  final db = AppDatabase();
  
  // Load saved settings
  final saved = await db.getSavedNotificationSettings();
  AppSettings initialSettings = const AppSettings();
  if (saved != null) {
    initialSettings = AppSettings(
      dailyVerseNotificationEnabled: saved['daily_verse_enabled'] == 1,
      readingTimeNotificationEnabled: saved['reading_time_enabled'] == 1,
      dailyVerseNotificationTime: saved['daily_verse_hour'] != null
          ? TimeOfDay(hour: saved['daily_verse_hour'] as int, minute: saved['daily_verse_minute'] as int)
          : null,
      readingTimeNotificationTime: saved['reading_time_hour'] != null
          ? TimeOfDay(hour: saved['reading_time_hour'] as int, minute: saved['reading_time_minute'] as int)
          : null,
      hasSeenOnboarding: saved['has_seen_onboarding'] == 1,
      hasSeenReaderHint: saved['has_seen_reader_hint'] == 1,
      lineHeight: (saved['line_height'] as num?)?.toDouble() ?? 1.6,
      marginScale: (saved['margin_scale'] as num?)?.toDouble() ?? 1.0,
      textAlign: (saved['text_align'] as int?) ?? 0,
      keepScreenOn: saved['keep_screen_on'] == 1,
    );
  }

  final settingsNotifier = ValueNotifier<AppSettings>(initialSettings);
  
  runApp(
    ProviderScope(
      overrides: [
        bibleRepositoryProvider.overrideWithValue(bibleRepository),
        settingsNotifierProvider.overrideWithValue(settingsNotifier),
      ],
      child: BibleRepositoryProvider(
        repository: bibleRepository,
        child: const BibleApp(),
      ),
    ),
  );
}

class BibleApp extends ConsumerWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BibleRepositoryProvider is already provided by main() with the same
    // instance that's registered in ProviderScope — don't create a second one.
    return Settings(
      notifier: ref.read(settingsNotifierProvider),
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: const _BibleMaterialApp(),
      ),
    );
  }
}

/// [MaterialApp] must read [Settings] so night mode updates the whole UI (not only the reader).
class _BibleMaterialApp extends ConsumerStatefulWidget {
  const _BibleMaterialApp();

  @override
  ConsumerState<_BibleMaterialApp> createState() => _BibleMaterialAppState();
}

class _BibleMaterialAppState extends ConsumerState<_BibleMaterialApp>
    with WidgetsBindingObserver {
  static final _navigatorKey = GlobalKey<NavigatorState>();

  BibleRepository? _repo;
  StreamSubscription<Uri>? _linkSub;
  bool _deepLinksInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Releases the Local Web Reader's port when the app is being torn down.
  ///
  /// `detached` only. Backgrounding the app must *not* stop the server —
  /// reading on a laptop while the phone sits face down is the entire point of
  /// the feature, and an Android foreground service keeps the process alive and
  /// network-reachable for exactly that. The server stays visible and stoppable
  /// the whole time through that service's notification.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      unawaited(ref.read(webReaderProvider.notifier).stopForLifecycle());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = BibleRepositoryProvider.of(context);

    // Set the navigator key for NotificationService to handle notification taps
    NotificationService.instance.navigatorKey = _navigatorKey;

    if (!_deepLinksInitialized) {
      _deepLinksInitialized = true;
      unawaited(_initDeepLinks());

      // Restore scheduled notifications based on current settings
      final settings = Settings.of(context);
      unawaited(
        NotificationService.instance.restoreScheduledNotifications(settings),
      );
    }
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(initial));
    }
    _linkSub = appLinks.uriLinkStream.listen(_handleUri);
  }

  Future<void> _handleUri(Uri uri) async {
    final repo = _repo;
    if (repo == null) return;
    final index = await repo.loadIndex();
    final target = parseDeepLink(uri, index);
    // All context/navigator access deferred to next frame to avoid async-gap lint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target == null) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
            const SnackBar(content: Text('Verse link not found')),
          );
        }
        return;
      }
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            entry: target.entry,
            initialChapterNumber: target.chapter,
            initialVerse: target.verse,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'መጽሐፍ ቅዱስ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.isDarkReader ? ThemeMode.dark : ThemeMode.light,
      home: settings.hasSeenOnboarding
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
