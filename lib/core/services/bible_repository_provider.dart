import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/books/data/repositories/bible_repository.dart';

/// Overridden in [main.dart] next to [BibleRepositoryProvider] so Riverpod
/// can load the index without a [BuildContext].
final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => throw StateError('bibleRepositoryProvider was not overridden'),
);
