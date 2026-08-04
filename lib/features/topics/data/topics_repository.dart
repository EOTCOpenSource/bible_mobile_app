import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../features/books/data/repositories/bible_repository.dart';
import 'topic_models.dart';

class TopicsRepository {
  TopicsRepository({required BibleRepository bibleRepo})
      : _bibleRepo = bibleRepo;

  final BibleRepository _bibleRepo;
  List<TopicEntry>? _topicsCache;

  /// Page size for paginated topic verse loading.
  static const int pageSize = 20;

  Future<List<TopicEntry>> loadTopics() async {
    if (_topicsCache != null) return _topicsCache!;
    final raw = await rootBundle.loadString('assets/topics/topics.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _topicsCache = list
        .map((e) => TopicEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return _topicsCache!;
  }

  /// One page of verses matching the topic's keywords.
  ///
  /// Each keyword is searched separately and the hits are concatenated in
  /// keyword order, deduplicated by book/chapter/verse. That order is stable
  /// across calls, which is what makes slicing a page out of it safe: page 2
  /// re-derives the same prefix page 1 returned and takes what comes after.
  ///
  /// Pagination happens after the merge rather than inside the FTS query,
  /// because dedup means N hits from the database do not correspond to N
  /// results — only the merged list can be counted on.
  Future<List<TopicVerse>> searchTopicVerses(
    TopicEntry topic, {
    int offset = 0,
    int limit = pageSize,
  }) async {
    // The merged list has to reach past [offset] before a page can be cut from
    // it. Filling only [limit] leaves nothing beyond the first page, which is
    // what used to end infinite scroll after one screen.
    final target = offset + limit;

    final seen = <String>{};
    final merged = <TopicVerse>[];

    for (final keyword in topic.keywords) {
      if (merged.length >= target) break;

      // Also [target], not the remaining count: duplicates of earlier keywords
      // do not add to the merge, so asking for only the shortfall can come
      // back short and stall the paging.
      final hits = await _bibleRepo.searchVerses(keyword, limit: target);

      for (final hit in hits) {
        final key = '${hit.bookEntry.id}:${hit.chapter}:${hit.verse}';
        if (!seen.add(key)) continue;

        merged.add(TopicVerse(
          bookNameAm: hit.bookEntry.bookNameAm,
          bookNameEn: hit.bookEntry.bookNameEn,
          chapter: hit.chapter,
          verse: hit.verse,
          text: hit.text,
          bookIndexEntry: hit.bookEntry,
        ));
      }
    }

    if (offset >= merged.length) return const [];
    return merged.sublist(offset, target.clamp(0, merged.length));
  }

  /// Returns the total estimated count of verses for a topic.
  /// Used to show verse counts on topic cards.
  Future<int> countTopicVerses(TopicEntry topic) async {
    final seen = <String>{};
    int count = 0;

    for (final keyword in topic.keywords) {
      final hits = await _bibleRepo.searchVerses(
        keyword,
        limit: 500,
      );
      for (final hit in hits) {
        final key = '${hit.bookEntry.id}:${hit.chapter}:${hit.verse}';
        if (seen.add(key)) count++;
      }
    }

    return count;
  }
}
