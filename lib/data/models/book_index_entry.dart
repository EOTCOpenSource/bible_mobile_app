class BookIndexEntry {
  final int bookNumber;
  final String bookNameAm;
  final String bookNameEn;
  final String bookShortNameAm;
  final String bookShortNameEn;
  final String testament;
  final String filename;
  final int? chapterCount;

  const BookIndexEntry({
    required this.bookNumber,
    required this.bookNameAm,
    required this.bookNameEn,
    required this.bookShortNameAm,
    required this.bookShortNameEn,
    required this.testament,
    required this.filename,
    this.chapterCount,
  });

  bool get isOldTestament => testament.toLowerCase().contains('old');

  factory BookIndexEntry.fromJson(Map<String, dynamic> json) {
    return BookIndexEntry(
      bookNumber: json['book_number'] as int,
      bookNameAm: (json['book_name_am'] as String?) ?? '',
      bookNameEn: (json['book_name_en'] as String?) ?? '',
      bookShortNameAm: (json['book_short_name_am'] as String?) ?? '',
      bookShortNameEn: (json['book_short_name_en'] as String?) ?? '',
      testament: (json['testament'] as String?) ?? '',
      filename: (json['file'] as String?) ?? '',
      chapterCount: json['chapter_count'] as int?,
    );
  }
}
