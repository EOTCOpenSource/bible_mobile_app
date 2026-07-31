import 'dart:convert';

/// One poetic line of a verse (`verse.lines` in the edition database).
///
/// `style` is a USFM paragraph marker: `p` for prose, `q1`/`q2`/`q3` for
/// increasing poetic indent. Present only on multi-line verses; when it is
/// empty the joined [Verse.text] is the whole verse.
class VerseLine {
  const VerseLine({required this.style, required this.text});

  final String style;
  final String text;

  /// Indent depth 0–3 derived from `q1`/`q2`/`q3`; prose is 0.
  int get indent {
    if (style.length < 2 || !style.startsWith('q')) return 0;
    return int.tryParse(style.substring(1))?.clamp(0, 3) ?? 0;
  }

  factory VerseLine.fromJson(Map<String, dynamic> j) => VerseLine(
        style: (j['style'] as String?) ?? 'p',
        text: (j['t'] as String?) ?? '',
      );
}

/// A cross reference attached to a verse (`verse.refs`).
class CrossRef {
  const CrossRef({required this.origin, required this.target});

  /// The reference this note hangs off, in the edition's own numerals ("1፥1").
  final String origin;

  /// The referenced passages, already formatted for display.
  final String target;

  factory CrossRef.fromJson(Map<String, dynamic> j) => CrossRef(
        origin: (j['origin'] as String?) ?? '',
        target: (j['target'] as String?) ?? '',
      );
}

/// A translator's footnote attached to a verse (`verse.notes`).
class VerseNote {
  const VerseNote({
    required this.caller,
    required this.origin,
    required this.text,
  });

  /// The marker printed in the text, usually `+`.
  final String caller;

  /// The lemma the note comments on. In this dataset the note body is often
  /// carried here with [text] empty, so readers should fall back between them.
  final String origin;
  final String text;

  /// Whichever of [text]/[origin] actually holds the note body.
  String get body => text.trim().isNotEmpty ? text : origin;

  factory VerseNote.fromJson(Map<String, dynamic> j) => VerseNote(
        caller: (j['caller'] as String?) ?? '+',
        origin: (j['origin'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
      );
}

class Verse {
  const Verse({
    required this.ord,
    required this.verseNumber,
    required this.label,
    required this.text,
    this.alt,
    this.lines = const [],
    this.refs = const [],
    this.notes = const [],
  });

  /// Position within the chapter. **Always** safe to sort by; [verseNumber] is
  /// not, because a handful of verses carry only a cross reference and have no
  /// number of their own.
  final int ord;

  /// The verse number, or a negative sentinel `-(ord + 1)` for the ~100 verses
  /// across the corpus that are unnumbered.
  ///
  /// A sentinel rather than a nullable int so that verse keys, selection ranges
  /// and the annotation tables — which are all keyed on a non-null verse
  /// integer — keep working untouched. Negatives can never collide with a real
  /// verse number. Check [isNumbered] before showing it to a reader.
  final int verseNumber;

  /// Display string for the number, covering the odd ones (`3b`, `98a`, `70t`).
  /// Empty when the verse is unnumbered.
  final String label;

  /// Ge'ez numeral for this verse, when the edition supplies one.
  final String? alt;

  final String text;

  /// Poetic lines. Empty for prose verses — [text] is then the whole verse.
  /// Never render both: `lines` is [text] split, not extra content.
  final List<VerseLine> lines;

  final List<CrossRef> refs;
  final List<VerseNote> notes;

  bool get isNumbered => verseNumber > 0;

  /// Ge'ez-aware display number, falling back to [label] then the integer.
  String displayNumber({required bool useGeez}) {
    if (!isNumbered) return '';
    if (useGeez && alt != null && alt!.isNotEmpty) return alt!;
    return label.isNotEmpty ? label : '$verseNumber';
  }
}

/// What kind of heading precedes a run of verses.
///
/// Positional rather than nested because headings differ between editions;
/// nesting them would make a parallel view impossible.
enum HeadingKind {
  /// `ms1` — "ምዕራፍ 1". Redundant with the reader's own chapter header.
  major,

  /// `s1` — the section title.
  section,

  /// `d` — a descriptive superscription, e.g. a psalm's ascription.
  descriptive,

  /// `r` — a parallel-passage reference line.
  reference,

  unknown;

  static HeadingKind parse(String? raw) => switch (raw) {
        'major' => HeadingKind.major,
        'section' => HeadingKind.section,
        'descriptive' => HeadingKind.descriptive,
        'reference' => HeadingKind.reference,
        _ => HeadingKind.unknown,
      };
}

class Heading {
  const Heading({
    required this.kind,
    required this.style,
    required this.text,
    this.before,
  });

  final HeadingKind kind;
  final String style;
  final String text;

  /// The verse number this heading precedes; null means end of chapter.
  final int? before;
}

/// A run of verses sharing one heading boundary.
///
/// Built from the edition's positional headings rather than stored: everything
/// between one heading boundary and the next becomes a section, so the reader's
/// existing section-based layout keeps working.
class Section {
  const Section({
    required this.title,
    required this.verses,
    this.headings = const [],
  });

  /// Text of the first [HeadingKind.section] heading at this boundary, or ''.
  final String title;

  /// Every heading at this boundary, in document order, including the kinds
  /// [title] does not cover.
  final List<Heading> headings;

  final List<Verse> verses;

  Iterable<Heading> ofKind(HeadingKind kind) =>
      headings.where((h) => h.kind == kind);
}

class Chapter {
  const Chapter({
    required this.chapterNumber,
    required this.sections,
    this.alt,
  });

  final int chapterNumber;

  /// Ge'ez numeral for the chapter, when the edition supplies one.
  final String? alt;

  final List<Section> sections;

  List<Verse> get allVerses => sections.expand((s) => s.verses).toList();
}

class Book {
  const Book({
    required this.id,
    required this.bookNumber,
    required this.bookNameAm,
    required this.bookNameEn,
    required this.bookShortNameAm,
    required this.bookShortNameEn,
    required this.testament,
    required this.chapters,
    this.nativeName = '',
  });

  /// USFM id — `GEN`, `1ES`. Stable across editions and the key every local
  /// table uses.
  final String id;

  /// Display order within this edition. KJV puts Job at 18; the EOTC canon puts
  /// it at 27, so this is edition-specific and not an identity.
  final int bookNumber;

  final String bookNameAm;
  final String bookNameEn;
  final String bookShortNameAm;
  final String bookShortNameEn;

  /// The book's name in the edition's own language, which is not necessarily
  /// Amharic — `en-kjv` says "Genesis", `om-kitaaba` says "Seera Uumamaa".
  final String nativeName;

  final String testament;
  final List<Chapter> chapters;
}

// ── JSON column helpers ───────────────────────────────────────────────────────

/// `lines`, `refs` and `notes` are JSON strings in the database, null when
/// absent. Malformed JSON degrades to an empty list rather than taking down the
/// reader for one bad verse.
List<T> decodeJsonList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! String || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  } on FormatException {
    return const [];
  }
}
