import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_index_entry.dart';

class ReaderBreadcrumb extends StatelessWidget {
  const ReaderBreadcrumb({
    super.key,
    required this.entry,
    required this.chapter,
    required this.useGeez,
    required this.isAmharic,
    required this.s,
    required this.bgColor,
    required this.accentColor,
    required this.mutedColor,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool useGeez;
  final bool isAmharic;
  final AppStrings s;
  final Color bgColor;
  final Color accentColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final chNum   = useGeez ? toGeez(chapter.chapterNumber) : '${chapter.chapterNumber}';
    final bookTag = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    final testTag = entry.isOldTestament ? s.booksOldTestament : s.booksNewTestament;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          BreadcrumbChip(text: bookTag, accentColor: accentColor),
          const SizedBox(width: 8),
          BreadcrumbChip(text: '${s.chapterAbbr} $chNum', accentColor: accentColor),
          const Spacer(),
          Text(
            testTag,
            style: TextStyle(
              fontFamily: AppTypography.amharicCaption.fontFamily,
              fontSize: 10,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class BreadcrumbChip extends StatelessWidget {
  const BreadcrumbChip({
    super.key,
    required this.text,
    required this.accentColor,
  });

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.shiromeda,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }
}
