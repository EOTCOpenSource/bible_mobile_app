class CrossRef {
  const CrossRef({
    required this.book,
    required this.chapter,
    required this.verse,
    this.toVerse,
    required this.weight,
  });

  /// Target book number in 81-book Ethiopian canon (1..85).
  final int book;

  /// Target chapter number.
  final int chapter;

  /// Target verse number.
  final int verse;

  /// Target end verse (if range), nullable.
  final int? toVerse;

  /// Relevance weight (0..10), strongest link first.
  final int weight;

  factory CrossRef.fromJson(Map<String, dynamic> json) {
    return CrossRef(
      book: (json['book'] as num).toInt(),
      chapter: (json['chapter'] as num).toInt(),
      verse: (json['verse'] as num).toInt(),
      toVerse: json['toVerse'] != null ? (json['toVerse'] as num).toInt() : null,
      weight: (json['weight'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      if (toVerse != null) 'toVerse': toVerse,
      'weight': weight,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrossRef &&
          runtimeType == other.runtimeType &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse &&
          toVerse == other.toVerse &&
          weight == other.weight;

  @override
  int get hashCode =>
      book.hashCode ^
      chapter.hashCode ^
      verse.hashCode ^
      toVerse.hashCode ^
      weight.hashCode;

  @override
  String toString() {
    final range = toVerse != null && toVerse != verse ? '-$toVerse' : '';
    return 'CrossRef(book: $book, ch: $chapter, v: $verse$range, weight: $weight)';
  }
}
