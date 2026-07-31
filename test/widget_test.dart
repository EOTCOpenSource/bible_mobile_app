import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/services/bible_repository_provider.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/settings/settings_provider.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/main.dart';

void main() {
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
        ),
      ),
    );
    expect(find.byType(BibleApp), findsOneWidget);
  });
}
