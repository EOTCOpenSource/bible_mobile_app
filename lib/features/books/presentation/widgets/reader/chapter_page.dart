import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../../core/annotations/annotation_models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_index_entry.dart';

// ── Chapter page (PageView item) ──────────────────────────────────────────────

class ReaderChapterPage extends StatelessWidget {
  const ReaderChapterPage({
    super.key,
    required this.entry,
    required this.chapter,
    required this.isDark,
    required this.fontSize,
    required this.fontFamily,
    required this.titleFontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.useGeez,
    required this.isAmharic,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
    required this.annotations,
    this.spotlightVerseNum,
    this.spotlightKey,
    this.continuousReading = false,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isDark;
  final double fontSize;
  final String fontFamily;
  final String titleFontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool useGeez;
  final bool isAmharic;
  final bool Function(int chNum, int secIdx, int verseNum) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int chNum, int secIdx, int verseNum) verseKeyFn;
  final int? spotlightVerseNum;
  final GlobalKey? spotlightKey;
  final ChapterAnnotations annotations;
  final bool continuousReading;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;

  /// Opens the footnote / cross-reference sheet for a verse.
  final void Function(Verse verse)? onApparatusTap;

  @override
  Widget build(BuildContext context) {
    // Index 0 → ChapterHeader, index i+1 → section[i]
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 80),
      // Pre-build all sections when navigating to a specific verse so that
      // _spotlightKey.currentContext is non-null and ensureVisible can scroll to it.
      // ignore: deprecated_member_use
      cacheExtent: spotlightVerseNum != null ? 30000.0 : null,
      itemCount: chapter.sections.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return ChapterHeader(
            entry:       entry,
            chapter:     chapter,
            isAmharic:   isAmharic,
            isDark:      isDark,
            accentColor: accentColor,
            textColor:   textColor,
            mutedColor:  mutedColor,
            titleFontFamily: titleFontFamily,
          );
        }
        final secIdx = i - 1;
        return SectionView(
          section:          chapter.sections[secIdx],
          secIdx:           secIdx,
          chapter:          chapter,
          fontSize:         fontSize,
          fontFamily:       fontFamily,
          titleFontFamily:  titleFontFamily,
          textColor:        textColor,
          accentColor:      accentColor,
          isDark:           isDark,
          useGeez:          useGeez,
          isSelectedFn:     isSelectedFn,
          onVerseTap:       onVerseTap,
          verseKeyFn:       verseKeyFn,
          annotations:      annotations,
          spotlightVerseNum: spotlightVerseNum,
          spotlightKey:     spotlightKey,
          continuousReading: continuousReading,
          onNoteTap:        onNoteTap,
          onApparatusTap:   onApparatusTap,
        );
      },
    );
  }
}

// ── Chapter header (illuminated initial + book title) ─────────────────────────

class ChapterHeader extends StatelessWidget {
  const ChapterHeader({
    super.key,
    required this.entry,
    required this.chapter,
    required this.isAmharic,
    required this.isDark,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.titleFontFamily,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isAmharic;
  final bool isDark;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final String titleFontFamily;

  String get _firstSectionTitle {
    for (final sec in chapter.sections) {
      if (sec.title.trim().isNotEmpty) return sec.title;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bookName     = isAmharic ? entry.bookNameAm : entry.bookNameEn;
    final altName      = isAmharic ? entry.bookNameEn : entry.bookNameAm;
    final shortName    = entry.bookShortNameAm.isNotEmpty
        ? entry.bookShortNameAm
        : entry.bookShortNameEn;
    final sectionTitle = _firstSectionTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illuminated initial
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2420)
                      : context.colors.parchmentDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  shortName,
                  style: TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: shortName.length <= 2 ? 22 : 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 14),
              // Title block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookName,
                      style: TextStyle(
                        fontFamily: titleFontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                    if (altName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        altName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: mutedColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (sectionTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        sectionTitle,
                        style: TextStyle(
                          fontFamily: titleFontFamily,
                          fontSize: 13,
                          color: accentColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: accentColor.withValues(alpha: 0.25),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Section (title + inline verses) ──────────────────────────────────────────

class SectionView extends StatelessWidget {
  const SectionView({
    super.key,
    required this.section,
    required this.secIdx,
    required this.chapter,
    required this.fontSize,
    required this.fontFamily,
    required this.titleFontFamily,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
    required this.annotations,
    this.spotlightVerseNum,
    this.spotlightKey,
    this.continuousReading = false,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final Section section;
  final int secIdx;
  final Chapter chapter;
  final double fontSize;
  final String fontFamily;
  final String titleFontFamily;
  final Color textColor;
  final Color accentColor;
  final bool isDark;
  final bool useGeez;
  final bool Function(int, int, int) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int, int, int) verseKeyFn;
  final ChapterAnnotations annotations;
  final int? spotlightVerseNum;
  final GlobalKey? spotlightKey;
  final bool continuousReading;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;
  final void Function(Verse verse)? onApparatusTap;

  @override
  Widget build(BuildContext context) {
    // Section 0 title is shown in ChapterHeader; skip it here
    final showTitle = secIdx > 0 && section.title.trim().isNotEmpty;

    // `major` headings are the edition's own "ምዕራፍ 1" chapter markers, which
    // the reader already prints in its chapter header — rendering them too
    // would repeat the chapter number twice on every page.
    final descriptive = section
        .ofKind(HeadingKind.descriptive)
        .where((h) => h.text.trim().isNotEmpty)
        .toList();
    final references = section
        .ofKind(HeadingKind.reference)
        .where((h) => h.text.trim().isNotEmpty)
        .toList();

    final List<Widget> verseChildren = continuousReading
        ? [
            _ContinuousSection(
              section:          section,
              secIdx:           secIdx,
              chapter:          chapter,
              fontSize:         fontSize,
              fontFamily:       fontFamily,
              textColor:        textColor,
              accentColor:      accentColor,
              isDark:           isDark,
              useGeez:          useGeez,
              isSelectedFn:     isSelectedFn,
              onVerseTap:       onVerseTap,
              verseKeyFn:       verseKeyFn,
              annotations:      annotations,
              spotlightVerseNum: spotlightVerseNum,
              spotlightKey:     spotlightKey,
              onNoteTap:        onNoteTap,
            ),
          ]
        : section.verses
            .map((verse) => VerseView(
                  verse: verse,
                  verseKey: verseKeyFn(
                      chapter.chapterNumber, secIdx, verse.verseNumber),
                  selected: isSelectedFn(
                      chapter.chapterNumber, secIdx, verse.verseNumber),
                  isSpotlight: spotlightVerseNum == verse.verseNumber,
                  spotlightKey: spotlightVerseNum == verse.verseNumber
                      ? spotlightKey
                      : null,
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
                ))
            .toList();

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
          // Parallel-passage line (`r`), e.g. "ማቴ 3፥1-12፤ ሉቃ 3፥1-9".
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
          // Descriptive superscription (`d`) — a psalm's ascription, which is
          // part of the text in this tradition rather than an editorial title.
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
          ...verseChildren,
        ],
      ),
    );
  }
}

// ── One verse ────────────────────────────────────────────────────────────────

/// A single tappable verse with its number, annotations and apparatus marker.
///
/// Extracted from [SectionView] so the parallel reader renders the primary
/// column with exactly the same widget — a second copy of this drifts the two
/// views apart the first time highlighting or bookmarking changes.
class VerseView extends StatelessWidget {
  const VerseView({
    super.key,
    required this.verse,
    required this.verseKey,
    required this.selected,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.annotations,
    required this.onVerseTap,
    this.isSpotlight = false,
    this.spotlightKey,
    this.onNoteTap,
    this.onApparatusTap,
  });

  final Verse verse;
  final String verseKey;
  final bool selected;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color accentColor;
  final bool isDark;
  final bool useGeez;
  final ChapterAnnotations annotations;
  final ValueChanged<String> onVerseTap;
  final bool isSpotlight;
  final GlobalKey? spotlightKey;
  final void Function(String verseKey, ChapterAnnotations annotations)? onNoteTap;
  final void Function(Verse verse)? onApparatusTap;

  @override
  Widget build(BuildContext context) {
    // The edition supplies the Ge'ez numeral in `alt` and the display label —
    // which covers the odd ones like `3b` — so neither is computed here.
    final numStr       = verse.displayNumber(useGeez: useGeez);
    final hlColor      = annotations.highlightColor(verse.verseNumber);
    final isBookmarked = annotations.isBookmarked(verse.verseNumber);
    final hasNote      = annotations.noteFor(verse.verseNumber) != null;
    final hasApparatus = verse.refs.isNotEmpty || verse.notes.isNotEmpty;

    final bgColor = selected
        ? (hlColor?.withValues(alpha: 0.5) ??
            accentColor.withValues(alpha: isDark ? 0.18 : 0.15))
        : (hlColor?.withValues(alpha: 0.28) ?? Colors.transparent);

    final numberSpan = TextSpan(
      text: numStr.isEmpty ? '' : '$numStr ',
      style: TextStyle(
        fontFamily: AppTypography.nokiaPureheadline,
        fontSize: fontSize * 0.62,
        fontWeight: FontWeight.w700,
        color: accentColor,
      ),
    );
    final bodyStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.85,
      color: textColor,
      fontWeight: FontWeight.w400,
    );
    // A superscript marker rather than the footnote text itself: Genesis 1:1
    // carries fourteen cross references and would bury the verse it belongs to.
    final apparatusSpan = hasApparatus
        ? WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: GestureDetector(
              onTap: () => onApparatusTap?.call(verse),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2),
                child: Text(
                  verse.notes.isNotEmpty ? '✻' : '→',
                  style: TextStyle(
                    fontSize: fontSize * 0.5,
                    color: accentColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          )
        : null;

    // `lines` is `text` split by poetic line, never extra content — render one
    // or the other, never both.
    final Widget verseBody = verse.lines.isEmpty
        ? RichText(
            text: TextSpan(children: [
              numberSpan,
              TextSpan(text: verse.text, style: bodyStyle),
              ?apparatusSpan,
            ]),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var li = 0; li < verse.lines.length; li++)
                Padding(
                  padding: EdgeInsets.only(
                    left: verse.lines[li].indent * (fontSize * 0.9),
                  ),
                  child: RichText(
                    text: TextSpan(children: [
                      if (li == 0) numberSpan,
                      TextSpan(text: verse.lines[li].text, style: bodyStyle),
                      if (li == verse.lines.length - 1) ?apparatusSpan,
                    ]),
                  ),
                ),
            ],
          );

    Widget verseWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          key: isSpotlight ? spotlightKey : null,
          onTap: () => onVerseTap(verseKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 2),
            padding: EdgeInsets.fromLTRB(isBookmarked ? 3 : 6, 4, 6, 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: isBookmarked
                  ? Border(left: BorderSide(color: accentColor, width: 3))
                  : null,
            ),
            child: verseBody,
          ),
        ),
        if (hasNote)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onNoteTap?.call(verseKey, annotations),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.sticky_note_2_rounded,
                  size: 13,
                  color: context.colors.accentDeep,
                ),
              ),
            ),
          ),
      ],
    );

    if (isSpotlight) {
      verseWidget =
          SpotlightWrapper(accentColor: accentColor, child: verseWidget);
    }
    return verseWidget;
  }
}

// ── Continuous reading section ────────────────────────────────────────────────

class _ContinuousSection extends StatefulWidget {
  const _ContinuousSection({
    required this.section,
    required this.secIdx,
    required this.chapter,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
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
  });

  final Section section;
  final int secIdx;
  final Chapter chapter;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
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

  @override
  State<_ContinuousSection> createState() => _ContinuousSectionState();
}

class _ContinuousSectionState extends State<_ContinuousSection> {
  final Map<int, TapGestureRecognizer> _recs = {};

  void _syncRecognizers() {
    final verseNums = widget.section.verses.map((v) => v.verseNumber).toSet();
    for (final vn in _recs.keys.toList()) {
      if (!verseNums.contains(vn)) _recs.remove(vn)!.dispose();
    }
    for (final vn in verseNums) {
      _recs.putIfAbsent(vn, () => TapGestureRecognizer());
    }
  }

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(_ContinuousSection old) {
    super.didUpdateWidget(old);
    _syncRecognizers();
  }

  @override
  void dispose() {
    for (final r in _recs.values) {
      r.dispose();
    }
    super.dispose();
  }

  bool get _sectionHasSpotlight =>
      widget.spotlightVerseNum != null &&
      widget.section.verses.any((v) => v.verseNumber == widget.spotlightVerseNum);

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    for (final verse in widget.section.verses) {
      final key = widget.verseKeyFn(
          widget.chapter.chapterNumber, widget.secIdx, verse.verseNumber);
      final selected = widget.isSelectedFn(
          widget.chapter.chapterNumber, widget.secIdx, verse.verseNumber);
      final hlColor = widget.annotations.highlightColor(verse.verseNumber);
      final isBookmarked = widget.annotations.isBookmarked(verse.verseNumber);
      final hasNote = widget.annotations.noteFor(verse.verseNumber) != null;
      final numStr = verse.displayNumber(useGeez: widget.useGeez);

      final rec = _recs[verse.verseNumber]!;
      rec.onTap = () => widget.onVerseTap(key);

      final bgColor = selected
          ? (hlColor?.withValues(alpha: 0.5) ??
              widget.accentColor.withValues(alpha: widget.isDark ? 0.18 : 0.15))
          : hlColor?.withValues(alpha: 0.28);

      // Verse number — pill with accent background when bookmarked, plain otherwise
      if (isBookmarked) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              numStr,
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: widget.fontSize * 0.58,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$numStr ',
          style: TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: widget.fontSize * 0.62,
            fontWeight: FontWeight.w700,
            color: widget.accentColor,
          ),
        ));
      }

      // Verse text — tappable
      spans.add(TextSpan(
        text: verse.text,
        recognizer: rec,
        style: TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          height: 1.85,
          color: widget.textColor,
          backgroundColor: bgColor,
        ),
      ));

      // Note indicator — tappable inline icon
      if (hasNote) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: GestureDetector(
            onTap: () => widget.onNoteTap?.call(key, widget.annotations),
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                Icons.sticky_note_2_rounded,
                size: 11,
                color: context.colors.accentDeep,
              ),
            ),
          ),
        ));
      }

      spans.add(const TextSpan(text: ' '));
    }

    return RichText(
      key: _sectionHasSpotlight ? widget.spotlightKey : null,
      text: TextSpan(children: spans),
    );
  }
}

// ── Spotlight glow wrapper ────────────────────────────────────────────────────

class SpotlightWrapper extends StatefulWidget {
  const SpotlightWrapper({
    super.key,
    required this.accentColor,
    required this.child,
  });
  final Color accentColor;
  final Widget child;

  @override
  State<SpotlightWrapper> createState() => _SpotlightWrapperState();
}

class _SpotlightWrapperState extends State<SpotlightWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    _anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: t > 0.01
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: t * 0.55),
                      blurRadius: t * 18,
                      spreadRadius: t * 2,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
