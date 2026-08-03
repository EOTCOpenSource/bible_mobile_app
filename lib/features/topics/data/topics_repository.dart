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

  /// Searches the Bible database for verses matching the topic's keywords.
  ///
  /// Uses the existing FTS5 search with pagination support via [offset].
  /// Results from all keywords are merged and deduplicated.
  Future<List<TopicVerse>> searchTopicVerses(
    TopicEntry topic, {
    int offset = 0,
    int limit = pageSize,
  }) async {
    final seen = <String>{};
    final results = <TopicVerse>[];

    for (final keyword in topic.keywords) {
      if (results.length >= limit) break;

      final hits = await _bibleRepo.searchVerses(
        keyword,
        limit: limit - results.length + offset,
        offset: 0,
      );

      for (final hit in hits) {
        final key = '${hit.bookEntry.id}:${hit.chapter}:${hit.verse}';
        if (seen.contains(key)) continue;
        seen.add(key);

        results.add(TopicVerse(
          bookNameAm: hit.bookEntry.bookNameAm,
          bookNameEn: hit.bookEntry.bookNameEn,
          chapter: hit.chapter,
          verse: hit.verse,
          text: hit.text,
          bookIndexEntry: hit.bookEntry,
        ));
      }
    }

    // Apply pagination on the merged, deduplicated results.
    if (offset >= results.length) return [];
    final end = (offset + limit).clamp(0, results.length);
    return results.sublist(offset, end);
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
