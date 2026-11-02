import 'package:flutter/foundation.dart';

/// One passage that echoes a verse, as stored in `crossrefs.db`.
///
/// Books are USFM ids (`JHN`), not positions: a position is one edition's
/// display order and points at a different book in the next edition.
/// Chapter and verse are in am-2000 numbering — `tool/build_crossrefs.dart`
/// converts them from the KJV numbering the source data uses.
@immutable
class CrossRef {
  const CrossRef({
    required this.book,
    required this.chapter,
    required this.verse,
    int? toChapter,
    int? toVerse,
    required this.votes,
  })  : toChapter = toChapter ?? chapter,
        toVerse = toVerse ?? verse;

  final String book;
  final int chapter;
  final int verse;

  /// End of the passage; the same as [chapter]/[verse] for a single verse.
  final int toChapter;
  final int toVerse;

  /// openbible.info reader votes — how many people found this link useful.
  final int votes;

  bool get isRange => toChapter != chapter || toVerse != verse;

  @override
  bool operator ==(Object other) =>
      other is CrossRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse &&
      other.toChapter == toChapter &&
      other.toVerse == toVerse &&
      other.votes == votes;

  @override
  int get hashCode =>
      Object.hash(book, chapter, verse, toChapter, toVerse, votes);

  @override
  String toString() => 'CrossRef($book $chapter:$verse'
      '${isRange ? '-$toChapter:$toVerse' : ''}, votes: $votes)';
}
