import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/core/l10n/am_strings.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/books/presentation/pages/chapter_chooser_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late BibleRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('widget_intro_test');
    repo = BibleRepository(storage: BibleStorage(rootOverride: tmpDir));
    await repo.init();
  });

  tearDown(() async {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: BibleRepositoryProvider(
        repository: repo,
        child: Settings(
          notifier: ValueNotifier(const AppSettings()),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
  }

  testWidgets('BookIntroductionCard expands, collapses, and handles chapter selection', (tester) async {
    final entry = BookIndexEntry(
      bookNumber: 1,
      id: 'GEN',
      bookNameAm: 'ኦሪት ዘፍጥረት',
      bookNameEn: 'Genesis',
      bookShortNameAm: 'ዘፍ',
      bookShortNameEn: 'Gen',
      testament: 'OT',
      chapterCount: 50,
    );

    int? selectedChapter;

    final widget = BookIntroductionCard(
      entry: entry,
      s: AmStrings(),
      isAmharic: true,
      onSelectChapter: (ch) {
        selectedChapter = ch;
      },
    );

    await tester.pumpWidget(buildTestableWidget(widget));
    await tester.pumpAndSettle();

    // Verify "About this book" title appears
    expect(find.text('ስለዚህ መጽሐፍ'), findsOneWidget);
    expect(find.text('ተጨማሪ አንብብ'), findsOneWidget);

    // Tap "ተጨማሪ አንብብ" (Read More) to expand
    await tester.tap(find.text('ተጨማሪ አንብብ'));
    await tester.pumpAndSettle();

    // Verify "በትንሹ አሳይ" (Show Less) appears and themes/outline are visible
    expect(find.text('በትንሹ አሳይ'), findsOneWidget);
    expect(find.text('ርዕሶች'), findsOneWidget);
    expect(find.text('አብነት'), findsOneWidget);

    // Tap an outline chip
    final chipFinder = find.textContaining('1–11');
    expect(chipFinder, findsOneWidget);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(selectedChapter, equals(0)); // 0-based chapter index for chapter 1

    // Tap "በትንሹ አሳይ" (Show Less) to collapse back
    await tester.tap(find.text('በትንሹ አሳይ'));
    await tester.pumpAndSettle();
    expect(find.text('ተጨማሪ አንብብ'), findsOneWidget);
  });
}
