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
void _stubStartupPlugins() {
  const channels = <String, Object?>{
    'com.llfbandit.app_links/messages': null,
    'plugins.it_nomads.com/flutter_secure_storage': null,
  };

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  for (final entry in channels.entries) {
    final channel = MethodChannel(entry.key);
    messenger.setMockMethodCallHandler(channel, (_) async => entry.value);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }
}

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
  testWidgets('bundled edition unpacks and opens under a widget test', (
    WidgetTester tester,
  ) async {
    _stubStartupPlugins();

    final (tmp, repo) = await _bootRepository(tester, 'bibleflutter_init');
    addTearDown(() {
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
    _stubStartupPlugins();

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
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(BibleApp), findsOneWidget);
  });
}
