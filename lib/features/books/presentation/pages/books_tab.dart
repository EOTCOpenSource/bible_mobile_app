import 'package:flutter/material.dart';
import '../../data/models/book_index_entry.dart';
import '../../data/repositories/bible_repository.dart' show SearchScope;
import 'book_chooser_page.dart';
import 'chapter_chooser_page.dart';

/// Books tab: nested [Navigator] with book list → chapter grid → reader.
class BooksTab extends StatefulWidget {
  const BooksTab({super.key, this.onSearchTap});
  final void Function(SearchScope scope)? onSearchTap;

  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
  final GlobalKey<NavigatorState> _booksNavigatorKey =
      GlobalKey<NavigatorState>();

  void _openChapterChooser(BookIndexEntry entry) {
    _booksNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterChooserPage(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _booksNavigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BookChooserPage(
            onBookTap: _openChapterChooser,
            onSearchTap: widget.onSearchTap,
          ),
        );
      },
    );
  }
}
