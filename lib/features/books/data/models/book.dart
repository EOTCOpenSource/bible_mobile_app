class Verse {
  final int verseNumber;
  final String text;

  const Verse({required this.verseNumber, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verseNumber: json['verse'] as int,
      text: (json['text'] as String?) ?? '',
    );
  }
}

class Section {
  final String title;
  final List<Verse> verses;

  const Section({required this.title, required this.verses});

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      title: (json['title'] as String?) ?? '',
      verses: (json['verses'] as List)
          .map((v) => Verse.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Chapter {
  final int chapterNumber;
  final List<Section> sections;

  const Chapter({required this.chapterNumber, required this.sections});

  List<Verse> get allVerses =>
      sections.expand((s) => s.verses).toList();

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterNumber: json['chapter'] as int,
      sections: (json['sections'] as List)
          .map((s) => Section.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Book {
  final int bookNumber;
  final String bookNameAm;
  final String bookNameEn;
  final String bookShortNameAm;
  final String bookShortNameEn;
  final String testament;
  final List<Chapter> chapters;

  const Book({
    required this.bookNumber,
    required this.bookNameAm,
    required this.bookNameEn,
    required this.bookShortNameAm,
    required this.bookShortNameEn,
    required this.testament,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookNumber: json['book_number'] as int,
      bookNameAm: (json['book_name_am'] as String?) ?? '',
      bookNameEn: (json['book_name_en'] as String?) ?? '',
      bookShortNameAm: (json['book_short_name_am'] as String?) ?? '',
      bookShortNameEn: (json['book_short_name_en'] as String?) ?? '',
      testament: (json['testament'] as String?) ?? '',
      chapters: (json['chapters'] as List)
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
