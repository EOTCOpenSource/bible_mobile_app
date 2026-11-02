import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../../books/data/models/book_index_entry.dart';

/// What a new reader is offered before they have opened anything.
///
/// Ordered by how well each one works as a first thing to read rather than by
/// canon position: a Gospel, then the Psalms, then the opening of the Bible.
const kStarterBookIds = <String>['JHN', 'PSA', 'GEN', 'MAT', 'PRO'];

/// Fill the shelf, but never show fewer than this — an empty "start reading"
/// row would be the same dead end it replaces.
const int kMinStarterBooks = 2;

/// As many as the shelf shows at rest.
const int kStarterBookCount = 3;

/// Suggested books for a reader with no history, drawn from the installed
/// edition so nothing is offered that its canon does not carry.
final starterBooksProvider = FutureProvider<List<BookIndexEntry>>((ref) async {
  final index = await ref.watch(bibleRepositoryProvider).loadIndex();
  if (index.isEmpty) return const [];

  final byId = <String, BookIndexEntry>{for (final e in index) e.id: e};
  final picks = <BookIndexEntry>[
    for (final id in kStarterBookIds)
      if (byId[id] != null) byId[id]!,
  ];

  // An edition whose canon uses different ids still gets a shelf: fall back to
  // its own opening books rather than showing nothing.
  if (picks.length < kMinStarterBooks) {
    final chosen = picks.map((e) => e.id).toSet();
    for (final entry in index) {
      if (picks.length >= kMinStarterBooks) break;
      if (chosen.add(entry.id)) picks.add(entry);
    }
  }

  return picks.take(kStarterBookCount).toList(growable: false);
});
