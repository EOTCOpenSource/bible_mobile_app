import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';
import 'package:bibleflutter/features/topics/data/topic_models.dart';
import 'package:bibleflutter/features/topics/data/topics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _book = BookIndexEntry(
  id: 'PSA',
  bookNumber: 19,
  bookNameAm: 'መዝሙረ ዳዊት',
  bookNameEn: 'Psalms',
  bookShortNameAm: 'መዝ',
  bookShortNameEn: 'Ps',
  testament: 'OT',
);

SearchHit _hit(int n) => SearchHit(
      bookEntry: _book,
      chapter: 1 + n ~/ 30,
      verse: 1 + n % 30,
      text: 'verse $n',
      matchStart: 0,
      matchEnd: 1,
      editionId: 'test',
    );

/// Serves a fixed corpus per keyword, honouring [limit] the way FTS does.
class _FakeBibleRepo extends BibleRepository {
  _FakeBibleRepo(this.corpus);

  /// keyword -> the hit indices it matches, in rank order.
  final Map<String, List<int>> corpus;

  /// Every (keyword, limit) pair asked for, so the tests can show the search
  /// widens as the reader pages rather than re-asking for the same slice.
  final calls = <({String keyword, int limit})>[];

  @override
  Future<List<SearchHit>> searchVerses(
    String query, {
    SearchFilter filter = const SearchFilter(),
    int limit = 300,
    int offset = 0,
  }) async {
    calls.add((keyword: query, limit: limit));
    final ids = corpus[query] ?? const <int>[];
    return ids.skip(offset).take(limit).map(_hit).toList();
  }
}

TopicEntry _topic(List<String> keywords) => TopicEntry(
      id: 'prayer',
      labelAm: 'ጸሎት',
      labelEn: 'Prayer',
      icon: '🙏',
      keywords: keywords,
    );

String _key(TopicVerse v) => '${v.chapter}:${v.verse}';

void main() {
  group('topic verse pagination', () {
    test('the second page is full when one keyword runs dry', () async {
      // The regression, and why every real topic hit it: the loop stopped
      // collecting once it had `limit` items, so as soon as the first keyword
      // ran out the remaining keywords were never searched. The page came back
      // short, the screen read that as "no more", and the scroll died with
      // most of the topic's verses still unseen.
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({
          'ጸሎት': List.generate(25, (i) => i),
          'ጸለየ': List.generate(40, (i) => 100 + i),
        }),
      );
      final topic = _topic(['ጸሎት', 'ጸለየ']);

      final page2 = await repo.searchTopicVerses(topic, offset: 20, limit: 20);

      expect(page2, hasLength(20));
    });

    test('a single keyword pages cleanly too', () async {
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({'ጸሎት': List.generate(100, (i) => i)}),
      );
      final topic = _topic(['ጸሎት']);

      final page2 = await repo.searchTopicVerses(topic, offset: 20, limit: 20);

      expect(page2, hasLength(20));
    });

    test('pages tile the corpus with no gaps and no repeats', () async {
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({'ጸሎት': List.generate(100, (i) => i)}),
      );
      final topic = _topic(['ጸሎት']);

      final seen = <String>[];
      for (var offset = 0; offset < 100; offset += 20) {
        final page =
            await repo.searchTopicVerses(topic, offset: offset, limit: 20);
        expect(page, hasLength(20), reason: 'short page at offset $offset');
        seen.addAll(page.map(_key));
      }

      expect(seen, hasLength(100));
      expect(seen.toSet(), hasLength(100), reason: 'a verse was served twice');
    });

    test('a page picks up exactly where the previous one stopped', () async {
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({'ጸሎት': List.generate(60, (i) => i)}),
      );
      final topic = _topic(['ጸሎት']);

      final page1 = await repo.searchTopicVerses(topic, offset: 0, limit: 20);
      final page2 = await repo.searchTopicVerses(topic, offset: 20, limit: 20);

      expect(page1.map(_key).toSet().intersection(page2.map(_key).toSet()),
          isEmpty);
      // Page 2 is the continuation of the same stable ordering.
      final full = await repo.searchTopicVerses(topic, offset: 0, limit: 40);
      expect([...page1, ...page2].map(_key), full.map(_key));
    });

    test('the tail page is short and the one after it is empty', () async {
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({'ጸሎት': List.generate(25, (i) => i)}),
      );
      final topic = _topic(['ጸሎት']);

      final page2 = await repo.searchTopicVerses(topic, offset: 20, limit: 20);
      expect(page2, hasLength(5), reason: 'the last five verses');

      final page3 = await repo.searchTopicVerses(topic, offset: 40, limit: 20);
      expect(page3, isEmpty, reason: 'past the end stops the scroll');
    });

    test('duplicates across keywords do not eat into a page', () async {
      // Both keywords match the same first ten verses; a page must still be
      // filled out of what is genuinely distinct.
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({
          'ጸሎት': List.generate(10, (i) => i),
          'ጸለየ': [...List.generate(10, (i) => i), ...List.generate(30, (i) => 100 + i)],
        }),
      );
      final topic = _topic(['ጸሎት', 'ጸለየ']);

      final page1 = await repo.searchTopicVerses(topic, offset: 0, limit: 20);

      expect(page1, hasLength(20));
      expect(page1.map(_key).toSet(), hasLength(20), reason: 'deduplicated');
    });

    test('verses from a later keyword are reachable by paging', () async {
      final repo = TopicsRepository(
        bibleRepo: _FakeBibleRepo({
          'ጸሎት': List.generate(25, (i) => i),
          'ጸለየ': List.generate(25, (i) => 100 + i),
        }),
      );
      final topic = _topic(['ጸሎት', 'ጸለየ']);

      final page1 = await repo.searchTopicVerses(topic, offset: 0, limit: 20);
      final page2 = await repo.searchTopicVerses(topic, offset: 20, limit: 20);
      final page3 = await repo.searchTopicVerses(topic, offset: 40, limit: 20);

      final all = [...page1, ...page2, ...page3];
      expect(all, hasLength(50), reason: 'both keywords fully paged through');
      expect(all.map(_key).toSet(), hasLength(50));
    });

    test('the search widens as the reader pages deeper', () async {
      final fake = _FakeBibleRepo({'ጸሎት': List.generate(100, (i) => i)});
      final repo = TopicsRepository(bibleRepo: fake);
      final topic = _topic(['ጸሎት']);

      await repo.searchTopicVerses(topic, offset: 0, limit: 20);
      await repo.searchTopicVerses(topic, offset: 40, limit: 20);

      // Page 3 must ask for enough rows to reach past its own offset.
      expect(fake.calls.first.limit, 20);
      expect(fake.calls.last.limit, 60);
    });
  });
}
