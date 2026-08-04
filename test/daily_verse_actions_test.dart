import 'package:bibleflutter/core/annotations/annotation_models.dart';
import 'package:bibleflutter/core/storage/app_database.dart';
import 'package:bibleflutter/core/storage/app_database_provider.dart';
import 'package:bibleflutter/features/annotations/providers/annotation_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The daily verse card writes bookmarks through the same chapter annotations
/// the reader uses, so a verse saved from Home is already saved when its
/// chapter opens. These exercise that shared path end to end against a real
/// database rather than asserting the button merely has a callback.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Saving a bookmark also nudges sync, which reads the auth token from
    // secure storage — a plugin with no implementation under test. Answering
    // null leaves the session unauthenticated and sync a no-op, which is the
    // state this is meant to exercise anyway.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  late ProviderContainer container;

  setUp(() async {
    // AppDatabase opens a fixed file, so without this every test — and every
    // run — inherits the bookmarks the last one left behind.
    await databaseFactory.deleteDatabase(
      p.join(await getDatabasesPath(), 'bibleapp.db'),
    );
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  /// The key the card builds for a daily verse in Jeremiah 31:33.
  const key = (bookId: 'JER', chapter: 31);
  const verse = 33;

  /// The notifier loads asynchronously from its constructor and exposes no
  /// future, so wait for it to leave AsyncLoading before asserting.
  Future<ChapterAnnotations> settled(
    ProviderContainer c,
    ChapterKey k,
  ) async {
    final provider = chapterAnnotationsProvider(k);
    var value = c.read(provider);
    for (var i = 0; i < 400 && value is AsyncLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      value = c.read(provider);
    }
    return value.value!;
  }

  Future<ChapterAnnotationsNotifier> notifier() async {
    final n = container.read(chapterAnnotationsProvider(key).notifier);
    await settled(container, key);
    return n;
  }

  test('bookmarking the daily verse saves it against its chapter', () async {
    final n = await notifier();

    expect(container.read(chapterAnnotationsProvider(key)).value!.isBookmarked(verse),
        isFalse);

    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    expect(container.read(chapterAnnotationsProvider(key)).value!.isBookmarked(verse),
        isTrue);
  });

  test('tapping it again removes the bookmark', () async {
    final n = await notifier();

    await n.toggleBookmark(verseStart: verse, bookNumber: 24);
    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    expect(container.read(chapterAnnotationsProvider(key)).value!.isBookmarked(verse),
        isFalse);
  });

  test('the bookmark lands where the reader looks for it', () async {
    final n = await notifier();
    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    // A second reader of the same chapter — what opening the reader does —
    // sees the bookmark without anything being passed between them.
    final fresh = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(container.read(appDatabaseProvider)),
    ]);
    addTearDown(fresh.dispose);

    final seen = await settled(fresh, key);
    expect(seen.isBookmarked(verse), isTrue);
  });

  test('only the verse that was bookmarked is marked', () async {
    final n = await notifier();
    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    final annotations = container.read(chapterAnnotationsProvider(key)).value!;
    expect(annotations.isBookmarked(verse), isTrue);
    expect(annotations.isBookmarked(verse - 1), isFalse);
    expect(annotations.isBookmarked(verse + 1), isFalse);
  });

  test('a different chapter is untouched', () async {
    final n = await notifier();
    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    const other = (bookId: 'JER', chapter: 30);
    final seen = await settled(container, other);
    expect(seen.isBookmarked(verse), isFalse);
  });

  test('the database survives a fresh AppDatabase over the same file', () async {
    final n = await notifier();
    await n.toggleBookmark(verseStart: verse, bookNumber: 24);

    final reopened = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(AppDatabase()),
    ]);
    addTearDown(reopened.dispose);

    final seen = await settled(reopened, key);
    expect(seen.isBookmarked(verse), isTrue,
        reason: 'a bookmark made on Home should outlive the app');
  });
}
