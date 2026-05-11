import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_index_entry.dart';
import '../models/book.dart';

class BibleRepository {
  static const _basePath = 'assets/bibledata';

  List<BookIndexEntry>? _index;
  final Map<String, Book> _bookCache = {};

  Future<List<BookIndexEntry>> loadIndex() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('$_basePath/index.json');
    final list = jsonDecode(raw) as List;
    _index = list
        .map((e) => BookIndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return _index!;
  }

  Future<Book> loadBook(BookIndexEntry entry) async {
    if (_bookCache.containsKey(entry.filename)) {
      return _bookCache[entry.filename]!;
    }
    final raw =
        await rootBundle.loadString('$_basePath/${entry.filename}');
    final book = Book.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _bookCache[entry.filename] = book;
    return book;
  }

  void clearCache() => _bookCache.clear();
}
