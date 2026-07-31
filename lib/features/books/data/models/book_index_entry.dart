/// A book in the active edition, as listed by the nav pane, choosers, search
/// scope and deep links.
///
/// Backed by the edition database's `book` table joined onto `catalog.db` for
/// localized names. [id] is the stable identity; [bookNumber] is only a display
/// order and changes between editions.
class BookIndexEntry {
  const BookIndexEntry({
    required this.id,
    required this.bookNumber,
    required this.bookNameAm,
    required this.bookNameEn,
    required this.bookShortNameAm,
    required this.bookShortNameEn,
    required this.testament,
    this.section,
    this.nativeName = '',
    this.canonOrd,
    this.chapterCount,
    this.verseCount,
  });

  /// USFM id — `GEN`, `1ES`, `XXC`.
  final String id;

  /// Position in this edition's own display order (1-based).
  final int bookNumber;

  /// Canon position, stable across editions. Sort a book list by [bookNumber];
  /// join across editions on [id].
  final int? canonOrd;

  final String bookNameAm;
  final String bookNameEn;
  final String bookShortNameAm;
  final String bookShortNameEn;

  /// The name in the edition's own language.
  final String nativeName;

  /// `old`, `deuterocanonical` or `new`.
  final String testament;

  /// Canon section — `Pentateuch`, `Historical`, `PoetryWisdom`,
  /// `MajorProphet`, `MinorProphet`, `Deuterocanonical`, `Gospel`, `Acts`,
  /// `PaulineEpistle`, `GeneralEpistle`, `Revelation`.
  ///
  /// Null for the Ethiopic appendix (Josippon, Didascalia, Clement …) and for
  /// the unsectioned deuterocanon, which is what the "other" filters catch.
  /// Filter on this rather than on [bookNumber]: display order differs between
  /// editions, so any numeric range is wrong for at least one of them.
  final String? section;

  final int? chapterCount;
  final int? verseCount;

  /// True for both `old` and `deuterocanonical`, matching how the reader has
  /// always split the two testaments. Use [isDeuterocanonical] when the
  /// distinction matters.
  bool get isOldTestament => !isNewTestament;

  bool get isNewTestament => testament.toLowerCase() == 'new';

  bool get isDeuterocanonical =>
      testament.toLowerCase() == 'deuterocanonical';

  @override
  bool operator ==(Object other) =>
      other is BookIndexEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
