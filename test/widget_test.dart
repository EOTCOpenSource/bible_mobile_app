import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/core/services/bible_repository_provider.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/settings/settings_provider.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/main.dart';

/// Silences the plugins the full app touches on startup but a widget test has
/// no implementation for.
///
/// These fire *after* the test body finishes — deep-link resolution and the
/// auth token read are both unawaited — and `flutter_test` fails a test on a
/// late exception, so stubbing them is what makes the smoke test meaningful
/// rather than permanently red.
void _stubStartupPlugins(WidgetTester tester) {
  const channels = <String, Object?>{
    'com.llfbandit.app_links/messages': null, // getInitialLink
    'plugins.it_nomads.com/flutter_secure_storage': null, // stored auth token
  };
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final entry in channels.entries) {
    final channel = MethodChannel(entry.key);
    messenger.setMockMethodCallHandler(channel, (_) async => entry.value);
    addTearDown(
      () => messenger.setMockMethodCallHandler(channel, null),
    );
  }
}

/// Sets up a repository backed by the bundled edition in a temp directory.
///
/// Every step runs inside [WidgetTester.runAsync], and that is load-bearing.
/// `testWidgets` installs a fake clock, but Dart dispatches file IO to a helper
/// isolate and replies over a `RawReceivePort` — even `Directory.createTemp`.
/// The fake clock never pumps those replies, so any real IO awaited directly in
/// a widget test hangs until the ten-minute timeout instead of failing.
Future<(Directory, BibleRepository)> _bootRepository(
  WidgetTester tester,
  String prefix,
) async {
  SharedPreferences.setMockInitialValues({});
  final booted = await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp(prefix);
    final repo = BibleRepository(storage: BibleStorage(rootOverride: dir));
    await repo.init();
    return (dir, repo);
  });
  return booted!;
}

void main() {
  testWidgets('bundled edition unpacks and opens under a widget test',
      (WidgetTester tester) async {
    final (tmp, repo) = await _bootRepository(tester, 'bibleflutter_init');
    // Tear-downs run last-registered-first, so the delete is registered first
    // and the dispose second. Windows refuses to remove a directory that still
    // holds an open SQLite handle.
    addTearDown(() {
      // Best effort: Windows keeps a lock on a database another part of the
      // still-running app may have reopened, and a temp directory the OS will
      // reap anyway is not worth failing a test over.
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      } on FileSystemException {
        // ignored
      }
    });
    addTearDown(repo.dispose);

    final index = await tester.runAsync<List<BookIndexEntry>>(repo.loadIndex);
    expect(repo.activeEditionId, 'am-2000');
    expect(index, isNotNull);
    expect(index!.length, greaterThan(80));

    await tester.pumpWidget(const SizedBox());
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('App renders without error', (WidgetTester tester) async {
    final bibleRepository = BibleRepository();
    final settingsNotifier = ValueNotifier<AppSettings>(const AppSettings());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bibleRepositoryProvider.overrideWithValue(bibleRepository),
          settingsNotifierProvider.overrideWithValue(settingsNotifier),
        ],
        child: BibleRepositoryProvider(
          repository: bibleRepository,
          child: const BibleApp(),
    _stubStartupPlugins(tester);
    final (tmp, repo) = await _bootRepository(tester, 'bibleflutter_widget');
    // Tear-downs run last-registered-first, so the delete is registered first
    // and the dispose second. Windows refuses to remove a directory that still
    // holds an open SQLite handle.
    addTearDown(() {
      // Best effort: Windows keeps a lock on a database another part of the
      // still-running app may have reopened, and a temp directory the OS will
      // reap anyway is not worth failing a test over.
      try {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      } on FileSystemException {
        // ignored
      }
    });
    addTearDown(repo.dispose);

    // Building HomeScreen opens the app database, and on desktop
    // sqflite_common_ffi runs it in its own isolate — the same fake-clock
    // problem, so the pump needs real async too.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibleRepositoryProvider.overrideWithValue(repo),
            // BibleApp reads this on its first build and the provider throws
            // unless overridden — main() supplies it in the real app.
            settingsNotifierProvider.overrideWithValue(
              ValueNotifier(const AppSettings()),
            ),
          ],
          child: BibleRepositoryProvider(
            repository: repo,
            child: const BibleApp(),
          ),
        ),
      );
    });

    expect(find.byType(BibleApp), findsOneWidget);
  });
}
