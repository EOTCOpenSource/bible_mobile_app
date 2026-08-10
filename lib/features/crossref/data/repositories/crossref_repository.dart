import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/cross_ref.dart';

class CrossRefRepository {
  CrossRefRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Max number of book JSONs kept in memory LRU cache.
  static const int _maxCacheSize = 5;

  /// In-memory cache: book number -> (verseKey -> `List<CrossRef>`)
  final Map<int, Map<String, List<CrossRef>>> _cache = {};

  /// Tracking book loading order for LRU eviction.
  final List<int> _lruOrder = [];

  /// Returns all cross-references for a given verse, ordered by weight (descending).
  Future<List<CrossRef>> getCrossRefs(int book, int chapter, int verse) async {
    final bookData = await _loadBookData(book);
    final key = '$book-$chapter-$verse';
    final refs = bookData[key];
    if (refs == null || refs.isEmpty) {
      return const [];
    }
    return List.unmodifiable(refs);
  }

  /// Helper: pre-load a book's cross-references into cache.
  Future<void> prefetchBook(int book) async {
    await _loadBookData(book);
  }

  /// Clear in-memory cache to manage memory footprint.
  void clearCache() {
    _cache.clear();
    _lruOrder.clear();
  }

  /// Internal loader with LRU eviction and defensive asset parsing.
  Future<Map<String, List<CrossRef>>> _loadBookData(int book) async {
    if (_cache.containsKey(book)) {
      // Refresh position in LRU list
      _lruOrder.remove(book);
      _lruOrder.add(book);
      return _cache[book]!;
    }

    final assetPath = 'assets/crossrefs/${book.toString().padLeft(2, '0')}.json';
    Map<String, List<CrossRef>> parsedBookMap = {};

    try {
      final jsonStr = await _bundle.loadString(assetPath);
      if (jsonStr.trim().isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          parsedBookMap = decoded.map((key, val) {
            if (val is List) {
              final list = val
                  .whereType<Map<String, dynamic>>()
                  .map((item) => CrossRef.fromJson(item))
                  .toList();
              list.sort((a, b) => b.weight.compareTo(a.weight));
              return MapEntry(key, list);
            }
            return MapEntry(key, <CrossRef>[]);
          });
        }
      }
    } catch (e) {
      debugPrint('[CrossRefRepository] Failed loading cross-ref asset $assetPath: $e');
      parsedBookMap = {};
    }

    // Enforce max capacity of 5 books
    if (_lruOrder.length >= _maxCacheSize) {
      final oldestBook = _lruOrder.removeAt(0);
      _cache.remove(oldestBook);
    }

    _cache[book] = parsedBookMap;
    _lruOrder.add(book);
    return parsedBookMap;
  }
}
