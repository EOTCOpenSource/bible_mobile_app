import 'package:flutter/material.dart';

import '../../../../../core/annotations/annotation_models.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_index_entry.dart';
import 'chapter_page.dart';

/// Width at which the two translations sit side by side rather than stacked.
///
/// Below it a phone gives each column ~160 dp, which is three or four Amharic
/// words per line — unreadable. Stacked pairs keep the alignment without the
/// ransom-note wrapping.
const double kParallelTwoColumnBreakpoint = 600;

/// A chapter rendered in two translations, aligned by verse number.
///
/// Alignment is by number and never by index: editions disagree about where
/// verses split — Genesis 1 is 31 verses in `am-2000` and 30 in `ti-1956` — so
/// walking two lists in lockstep silently pairs the wrong words together from
/// the first disagreement onwards.
///
/// Only the primary column is interactive. Bookmarks, highlights and notes key
/// on book/chapter/verse rather than on a translation, so a tap in either
/// column means the same verse; the primary is what renders the annotation so
/// that state cannot appear twice with two different looks.
class ParallelChapterPage extends StatelessWidget {
  const ParallelChapterPage({
    super.key,
    required this.entry,
    required this.chapter,
    required this.secondaryChapter,
    required this.secondaryBookMissing,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.isDark,
    required this.fontSize,
    required this.fontFamily,
    required this.titleFontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.useGeez,
    required this.isAmharic,
    required this.s,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
    required this.annotations,
    this.spotlightVerseNum,
    this.spotlightKey,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final BookIndexEntry entry;
  final Chapter chapter;

  /// The same chapter in the parallel edition. Null when that edition has the
  /// book but not this chapter — versification differs, so this is ordinary.
  final Chapter? secondaryChapter;

  /// True when the parallel edition's canon does not carry this book at all.
  final bool secondaryBookMissing;

  final String primaryLabel;
  final String secondaryLabel;

  final bool isDark;
  final double fontSize;
  final String fontFamily;
  final String titleFontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool useGeez;
  final bool isAmharic;
  final AppStrings s;

  final bool Function(int chNum, int secIdx, int verseNum) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int chNum, int secIdx, int verseNum) verseKeyFn;
  final ChapterAnnotations annotations;
  final int? spotlightVerseNum;
  final GlobalKey? spotlightKey;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;
  final void Function(Verse verse)? onApparatusTap;

  /// Secondary verses grouped onto the primary section that owns them.
  ///
  /// A secondary verse the primary does not have still has to be rendered, or
  /// switching the columns around would lose text. It joins the last section
  /// whose first verse number is at or below it, which is where a reader
  /// comparing the two would look for it.
  List<List<Verse>> _secondaryBySection() {
    final buckets = List.generate(chapter.sections.length, (_) => <Verse>[]);
    final secondary = secondaryChapter;
    if (secondary == null) return buckets;

    final starts = [
      for (final sec in chapter.sections)
        sec.verses
                .where((v) => v.isNumbered)
                .map((v) => v.verseNumber)
                .fold<int?>(null, (min, n) => min == null || n < min ? n : min) ??
            -1,
    ];

    for (final verse in secondary.allVerses) {
      // Unnumbered rows carry only a cross reference and have nothing to align
      // against; they are the apparatus of their own edition, not text.
      if (!verse.isNumbered) continue;
      var target = 0;
      for (var i = 0; i < starts.length; i++) {
        if (starts[i] >= 0 && starts[i] <= verse.verseNumber) target = i;
      }
      buckets[target].add(verse);
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final twoColumn =
        MediaQuery.sizeOf(context).width >= kParallelTwoColumnBreakpoint;
    final secondaryBuckets = _secondaryBySection();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 80),
      cacheExtent: spotlightVerseNum != null ? 30000 : null,
      itemCount: chapter.sections.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChapterHeader(
                entry: entry,
                chapter: chapter,
                isAmharic: isAmharic,
                isDark: isDark,
                accentColor: accentColor,
                textColor: textColor,
                mutedColor: mutedColor,
                titleFontFamily: titleFontFamily,
              ),
              if (secondaryBookMissing)
                _MissingNotice(
                  message: s.parallelBookMissing(secondaryLabel),
                  accentColor: accentColor,
                  mutedColor: mutedColor,
                  fontSize: fontSize,
                )
              else
                _ColumnLabels(
                  primaryLabel: primaryLabel,
                  secondaryLabel: secondaryLabel,
                  twoColumn: twoColumn,
                  accentColor: accentColor,
                  mutedColor: mutedColor,
                ),
            ],
          );
        }

        final secIdx = i - 1;
        return _ParallelSection(
          section: chapter.sections[secIdx],
          secondaryVerses: secondaryBuckets[secIdx],
          secIdx: secIdx,
          chapter: chapter,
          twoColumn: twoColumn && !secondaryBookMissing,
          showSecondary: !secondaryBookMissing,
          fontSize: fontSize,
          fontFamily: fontFamily,
          titleFontFamily: titleFontFamily,
          textColor: textColor,
          mutedColor: mutedColor,
          accentColor: accentColor,
          isDark: isDark,
          useGeez: useGeez,
          isSelectedFn: isSelectedFn,
          onVerseTap: onVerseTap,
          verseKeyFn: verseKeyFn,
          annotations: annotations,
          spotlightVerseNum: spotlightVerseNum,
          spotlightKey: spotlightKey,
          onNoteTap: onNoteTap,
          onApparatusTap: onApparatusTap,
        );
      },
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

/// One primary section and the secondary verses that align with it.
///
/// Headings — the section title, the parallel-passage line and any descriptive
/// superscription — come from the primary edition only. Two editions' headings
/// fall at different verses, so showing both would break the alignment the
/// whole view exists for.
class _ParallelSection extends StatelessWidget {
  const _ParallelSection({
    required this.section,
    required this.secondaryVerses,
    required this.secIdx,
    required this.chapter,
    required this.twoColumn,
    required this.showSecondary,
    required this.fontSize,
    required this.fontFamily,
    required this.titleFontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
    required this.annotations,
    this.spotlightVerseNum,
    this.spotlightKey,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final Section section;
  final List<Verse> secondaryVerses;
  final int secIdx;
  final Chapter chapter;
  final bool twoColumn;
  final bool showSecondary;
  final double fontSize;
  final String fontFamily;
  final String titleFontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool isDark;
  final bool useGeez;
  final bool Function(int, int, int) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int, int, int) verseKeyFn;
  final ChapterAnnotations annotations;
  final int? spotlightVerseNum;
  final GlobalKey? spotlightKey;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;
  final void Function(Verse verse)? onApparatusTap;

  /// The section's verses paired with their counterpart, in reading order.
  ///
  /// The primary edition sets the order — it is the one carrying the headings
  /// and the annotations, and its unnumbered verses have no number to sort by.
  /// A verse only one edition has still gets a row, with an empty cell opposite
  /// it, rather than shifting every later pair by one.
  List<({int number, Verse? primary, Verse? secondary})> get _rows {
    final secondaryByNumber = {
      for (final v in secondaryVerses) v.verseNumber: v,
    };
    final rows = <({int number, Verse? primary, Verse? secondary})>[];
    final paired = <int>{};

    for (final verse in section.verses) {
      final match =
          verse.isNumbered ? secondaryByNumber[verse.verseNumber] : null;
      if (match != null) paired.add(verse.verseNumber);
      rows.add((
        number: verse.verseNumber,
        primary: verse,
        secondary: match,
      ));
    }

    // What the parallel edition splits into a verse the primary does not have
    // — Tigrinya carries a Genesis 1:31 the Amharic folds into 1:30 — lands
    // just before the first primary verse numbered above it.
    for (final verse in secondaryVerses) {
      if (paired.contains(verse.verseNumber)) continue;
      var insertAt = rows.length;
      for (var i = 0; i < rows.length; i++) {
        final n = rows[i].number;
        if (n > 0 && n > verse.verseNumber) {
          insertAt = i;
          break;
        }
      }
      rows.insert(
        insertAt,
        (number: verse.verseNumber, primary: null, secondary: verse),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    // Section 0's title is shown in the chapter header; skip it here.
    final showTitle = secIdx > 0 && section.title.trim().isNotEmpty;
    final descriptive = section
        .ofKind(HeadingKind.descriptive)
        .where((h) => h.text.trim().isNotEmpty);
    final references = section
        .ofKind(HeadingKind.reference)
        .where((h) => h.text.trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                section.title,
                style: TextStyle(
                  fontFamily: titleFontFamily,
                  fontSize: fontSize - 2,
                  color: accentColor,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
          for (final h in references)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                h.text,
                style: TextStyle(
                  fontFamily: titleFontFamily,
                  fontSize: fontSize * 0.68,
                  color: accentColor.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          for (final h in descriptive)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                h.text,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize * 0.86,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.75),
                  height: 1.7,
                ),
              ),
            ),
          for (final row in _rows)
            _VersePair(
              key: ValueKey('${chapter.chapterNumber}:$secIdx:${row.number}'),
              primary: row.primary,
              secondary: row.secondary,
              verseKey: verseKeyFn(chapter.chapterNumber, secIdx, row.number),
              selected:
                  isSelectedFn(chapter.chapterNumber, secIdx, row.number),
              isSpotlight: spotlightVerseNum == row.number,
              spotlightKey:
                  spotlightVerseNum == row.number ? spotlightKey : null,
              twoColumn: twoColumn,
              showSecondary: showSecondary,
              fontSize: fontSize,
              fontFamily: fontFamily,
              textColor: textColor,
              mutedColor: mutedColor,
              accentColor: accentColor,
              isDark: isDark,
              useGeez: useGeez,
              annotations: annotations,
              onVerseTap: onVerseTap,
              onNoteTap: onNoteTap,
              onApparatusTap: onApparatusTap,
            ),
        ],
      ),
    );
  }
}

// ── One aligned verse ─────────────────────────────────────────────────────────

class _VersePair extends StatelessWidget {
  const _VersePair({
    super.key,
    required this.primary,
    required this.secondary,
    required this.verseKey,
    required this.selected,
    required this.isSpotlight,
    required this.spotlightKey,
    required this.twoColumn,
    required this.showSecondary,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.annotations,
    required this.onVerseTap,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final Verse? primary;
  final Verse? secondary;
  final String verseKey;
  final bool selected;
  final bool isSpotlight;
  final GlobalKey? spotlightKey;
  final bool twoColumn;
  final bool showSecondary;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool isDark;
  final bool useGeez;
  final ChapterAnnotations annotations;
  final ValueChanged<String> onVerseTap;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;
  final void Function(Verse verse)? onApparatusTap;

  Widget _primaryCell() {
    final verse = primary;
    if (verse == null) return const SizedBox.shrink();
    return VerseView(
      verse: verse,
      verseKey: verseKey,
      selected: selected,
      isSpotlight: isSpotlight,
      spotlightKey: spotlightKey,
      fontSize: fontSize,
      fontFamily: fontFamily,
      textColor: textColor,
      accentColor: accentColor,
      isDark: isDark,
      useGeez: useGeez,
      annotations: annotations,
      onVerseTap: onVerseTap,
      onNoteTap: onNoteTap,
      onApparatusTap: onApparatusTap,
    );
  }

  /// The parallel text: same verse, no annotation chrome, a shade quieter so
  /// the eye can tell at a glance which column it is reading.
  Widget _secondaryCell() {
    final verse = secondary;
    if (verse == null) return const SizedBox.shrink();

    final numStr = verse.displayNumber(useGeez: useGeez);
    return GestureDetector(
      onTap: () => onVerseTap(verseKey),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 2,
          left: twoColumn ? 0 : 10,
          top: twoColumn ? 0 : 2,
        ),
        padding: EdgeInsets.fromLTRB(twoColumn ? 6 : 8, 4, 6, 4),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: isDark ? 0.12 : 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: twoColumn
              ? null
              : Border(
                  left: BorderSide(
                    color: accentColor.withValues(alpha: 0.28),
                    width: 2,
                  ),
                ),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: numStr.isEmpty ? '' : '$numStr ',
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: fontSize * 0.58,
                fontWeight: FontWeight.w700,
                color: accentColor.withValues(alpha: 0.7),
              ),
            ),
            TextSpan(
              text: verse.text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize * 0.94,
                height: 1.8,
                color: textColor.withValues(alpha: 0.82),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showSecondary) return _primaryCell();

    if (twoColumn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _primaryCell()),
            const SizedBox(width: 14),
            Expanded(child: _secondaryCell()),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_primaryCell(), _secondaryCell()],
      ),
    );
  }
}

// ── Column labels and the missing-book notice ────────────────────────────────

class _ColumnLabels extends StatelessWidget {
  const _ColumnLabels({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.twoColumn,
    required this.accentColor,
    required this.mutedColor,
  });

  final String primaryLabel;
  final String secondaryLabel;
  final bool twoColumn;
  final Color accentColor;
  final Color mutedColor;

  Widget _chip(String text, {required bool strong}) => Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.nokiaPureheadline,
          fontSize: 9.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: strong
              ? accentColor.withValues(alpha: 0.85)
              : mutedColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 6),
      child: twoColumn
          ? Row(
              children: [
                Expanded(child: _chip(primaryLabel, strong: true)),
                const SizedBox(width: 14),
                Expanded(child: _chip(secondaryLabel, strong: false)),
              ],
            )
          : Row(
              children: [
                _chip(primaryLabel, strong: true),
                Text(
                  '  ·  ',
                  style: TextStyle(fontSize: 9.5, color: mutedColor),
                ),
                Flexible(child: _chip(secondaryLabel, strong: false)),
              ],
            ),
    );
  }
}

class _MissingNotice extends StatelessWidget {
  const _MissingNotice({
    required this.message,
    required this.accentColor,
    required this.mutedColor,
    required this.fontSize,
  });

  final String message;
  final Color accentColor;
  final Color mutedColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.shiromeda,
                fontSize: fontSize * 0.72,
                color: mutedColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
