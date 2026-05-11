import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.useGeez,
    required this.isAmharic,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isDark;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool useGeez;
  final bool isAmharic;
  final bool Function(int chNum, int secIdx, int verseNum) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int chNum, int secIdx, int verseNum) verseKeyFn;

  @override
  Widget build(BuildContext context) {
    // Index 0 → ChapterHeader, index i+1 → section[i]
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
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
          );
        }
        final secIdx = i - 1;
        return SectionView(
          section:      chapter.sections[secIdx],
          secIdx:       secIdx,
          chapter:      chapter,
          fontSize:     fontSize,
          fontFamily:   fontFamily,
          textColor:    textColor,
          accentColor:  accentColor,
          isDark:       isDark,
          useGeez:      useGeez,
          isSelectedFn: isSelectedFn,
          onVerseTap:   onVerseTap,
          verseKeyFn:   verseKeyFn,
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
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isAmharic;
  final bool isDark;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;

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
                      : AppColors.parchmentDark,
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
                        fontFamily: AppTypography.shiromeda,
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
                          fontFamily: AppTypography.abbaGarima,
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
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
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

  @override
  Widget build(BuildContext context) {
    // Section 0 title is shown in ChapterHeader; skip it here
    final showTitle = secIdx > 0 && section.title.trim().isNotEmpty;

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
                  fontFamily: AppTypography.abbaGarima,
                  fontSize: fontSize - 2,
                  color: accentColor,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
          // Inline verse: ‹number› text
          ...section.verses.map((verse) {
            final key      = verseKeyFn(chapter.chapterNumber, secIdx, verse.verseNumber);
            final selected = isSelectedFn(chapter.chapterNumber, secIdx, verse.verseNumber);
            final numStr   = useGeez ? toGeez(verse.verseNumber) : '${verse.verseNumber}';

            return GestureDetector(
              onTap: () => onVerseTap(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor.withValues(alpha: isDark ? 0.18 : 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$numStr ',
                        style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: fontSize * 0.62,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      TextSpan(
                        text: verse.text,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          height: 1.85,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
