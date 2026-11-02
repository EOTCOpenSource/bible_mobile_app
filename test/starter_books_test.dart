import 'package:bibleflutter/core/services/bible_repository_provider.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/home/providers/starter_books_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BookIndexEntry _entry(String id, int number) => BookIndexEntry(
      id: id,
      bookNumber: number,
      bookNameAm: id,
      bookNameEn: id,
      bookShortNameAm: id,
      bookShortNameEn: id,
      testament: 'OT',
      chapterCount: 10,
    );

/// Serves a fixed book index without touching an installed edition.
class _FakeBibleRepo extends BibleRepository {
  _FakeBibleRepo(this.index);

  final List<BookIndexEntry> index;

  @override
  Future<List<BookIndexEntry>> loadIndex() async => index;
}

Future<List<BookIndexEntry>> _starters(List<BookIndexEntry> index) async {
  final container = ProviderContainer(overrides: [
    bibleRepositoryProvider.overrideWithValue(_FakeBibleRepo(index)),
  ]);
  addTearDown(container.dispose);
  return container.read(starterBooksProvider.future);
}

void main() {
  test('offers a gospel first, then the psalms', () async {
    final picks = await _starters([
      _entry('GEN', 1),
      _entry('PSA', 19),
      _entry('MAT', 40),
      _entry('JHN', 43),
    ]);

    expect(picks.map((e) => e.id), ['JHN', 'PSA', 'GEN']);
  });

  test('never offers more than the shelf shows', () async {
    final picks = await _starters([
      for (final id in kStarterBookIds) _entry(id, 1),
    ]);

    expect(picks, hasLength(kStarterBookCount));
  });

  test('skips books this edition\'s canon does not carry', () async {
    // No John and no Genesis in this one.
    final picks = await _starters([
      _entry('PSA', 19),
      _entry('MAT', 40),
    ]);

    expect(picks.map((e) => e.id), ['PSA', 'MAT']);
  });

  test('an unfamiliar canon still gets a shelf', () async {
    // None of the preferred ids are present — fall back to its own books
    // rather than showing the reader nothing.
    final picks = await _starters([
      _entry('XXA', 1),
      _entry('XXB', 2),
      _entry('XXC', 3),
    ]);

    expect(picks.length, greaterThanOrEqualTo(kMinStarterBooks));
    expect(picks.map((e) => e.id), ['XXA', 'XXB']);
  });

  test('a canon with one preferred book is topped up to the minimum', () async {
    final picks = await _starters([
      _entry('AAA', 1),
      _entry('PSA', 19),
    ]);

    expect(picks.length, greaterThanOrEqualTo(kMinStarterBooks));
    expect(picks.map((e) => e.id), contains('PSA'));
    // Topping up must not serve the same book twice.
    expect(picks.map((e) => e.id).toSet(), hasLength(picks.length));
  });

  test('no edition installed means no suggestions, not a crash', () async {
    expect(await _starters([]), isEmpty);
  });
}
