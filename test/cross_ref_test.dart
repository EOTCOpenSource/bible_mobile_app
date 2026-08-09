import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/services/bible_repository_provider.dart';
import 'package:bibleflutter/core/services/repository_provider.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/books/data/bible_storage.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/crossref/data/models/cross_ref.dart';
import 'package:bibleflutter/features/crossref/data/repositories/crossref_repository.dart';
import 'package:bibleflutter/features/crossref/presentation/widgets/cross_ref_sheet.dart';
import 'package:bibleflutter/features/crossref/providers/crossref_providers.dart';

class MockCrossRefAssetBundle extends AssetBundle {
  final Map<String, String> assets;

  MockCrossRefAssetBundle(this.assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (assets.containsKey(key)) {
      return assets[key]!;
    }
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late BibleRepository bibleRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmpDir = await Directory.systemTemp.createTemp('cross_ref_widget_test');
    bibleRepo = BibleRepository(storage: BibleStorage(rootOverride: tmpDir));
    await bibleRepo.init();
  });

  tearDown(() async {
    bibleRepo.dispose();
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('CrossRef Data Model Tests', () {
    test('CrossRef json serialization and deserialization', () {
      final jsonMap = {
        'book': 45,
        'chapter': 5,
        'verse': 8,
        'toVerse': 10,
        'weight': 9,
      };

      final ref = CrossRef.fromJson(jsonMap);

      expect(ref.book, 45);
      expect(ref.chapter, 5);
      expect(ref.verse, 8);
      expect(ref.toVerse, 10);
      expect(ref.weight, 9);

      final serialized = ref.toJson();
      expect(serialized['book'], 45);
      expect(serialized['chapter'], 5);
      expect(serialized['verse'], 8);
      expect(serialized['toVerse'], 10);
      expect(serialized['weight'], 9);
    });

    test('CrossRef without optional toVerse defaults to null', () {
      final jsonMap = {
        'book': 62,
        'chapter': 4,
        'verse': 9,
        'weight': 7,
      };

      final ref = CrossRef.fromJson(jsonMap);
      expect(ref.toVerse, isNull);
      expect(ref.weight, 7);
    });
  });

  group('CrossRefRepository Tests', () {
    late CrossRefRepository repo;
    late MockCrossRefAssetBundle mockBundle;

    setUp(() {
      mockBundle = MockCrossRefAssetBundle({
        'assets/crossrefs/43.json': jsonEncode({
          '43-3-16': [
            {'book': 45, 'chapter': 5, 'verse': 8, 'weight': 9},
            {'book': 62, 'chapter': 4, 'verse': 9, 'weight': 7},
          ]
        }),
      });

      repo = CrossRefRepository(bundle: mockBundle);
    });

    test('Loads cross references for valid verse key', () async {
      final refs = await repo.getCrossRefs(43, 3, 16);
      expect(refs.length, 2);
      expect(refs.first.book, 45);
      expect(refs.first.weight, 9);
      expect(refs.last.book, 62);
      expect(refs.last.weight, 7);
    });

    test('Returns empty list for verse without cross references', () async {
      final refs = await repo.getCrossRefs(43, 1, 1);
      expect(refs, isEmpty);
    });

    test('Evicts LRU cache when maximum capacity is reached', () async {
      final customBundle = MockCrossRefAssetBundle({
        for (var b = 1; b <= 7; b++)
          'assets/crossrefs/${b.toString().padLeft(2, '0')}.json': jsonEncode({
            '$b-1-1': [
              {'book': 100, 'chapter': 1, 'verse': 1, 'weight': 5}
            ]
          }),
      });

      final lruRepo = CrossRefRepository(bundle: customBundle);

      // Access books 1 through 6 (max capacity is 5)
      for (var b = 1; b <= 6; b++) {
        await lruRepo.getCrossRefs(b, 1, 1);
      }

      // Book 1 should have been evicted
      final refs1 = await lruRepo.getCrossRefs(1, 1, 1);
      expect(refs1.first.book, 100);
    });
  });

  group('CrossRefSheet Widget Tests', () {
    testWidgets('Displays title and source reference', (WidgetTester tester) async {
      final mockBundle = MockCrossRefAssetBundle({
        'assets/crossrefs/43.json': jsonEncode({}),
      });
      final repo = CrossRefRepository(bundle: mockBundle);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            crossRefRepositoryProvider.overrideWithValue(repo),
            bibleRepositoryProvider.overrideWithValue(bibleRepo),
          ],
          child: BibleRepositoryProvider(
            repository: bibleRepo,
            child: Settings(
              notifier: ValueNotifier(const AppSettings()),
              child: L10n(
                initialLanguage: AppLanguage.amharic,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: Scaffold(
                    body: CrossRefSheet(
                      sourceBook: 43,
                      sourceChapter: 3,
                      sourceVerse: 16,
                      sourceReferenceLabel: 'ዮሐንስ 3:16',
                      onSelectCrossRef: (book, chapter, verse) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ዮሐንስ 3:16'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}

