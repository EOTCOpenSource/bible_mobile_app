import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book_index_entry.dart';
import '../edition_switcher.dart';

class ReaderToolbar extends StatelessWidget {
  const ReaderToolbar({
    super.key,
    required this.entry,
    required this.currentChapter,
    required this.useGeez,
    required this.isAmharic,
    required this.bgColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.sheetTheme,
    required this.s,
    required this.onBack,
    required this.onFontSettings,
    this.chapterNumber,
    this.onChapterTap,
    this.onAudio,
    this.onSearch,
    this.onGoToReference,
  });

  final BookIndexEntry entry;
  final int currentChapter;

  /// The chapter as the edition numbers it. Falls back to the page index when
  /// absent — books whose chapters do not start at 1 are the reason this is not
  /// derived from the index.
  final int? chapterNumber;

  /// Opens the chapter picker. The label has always carried a dropdown chevron;
  /// until this existed it was wired to nothing.
  final VoidCallback? onChapterTap;
  final bool useGeez;
  final bool isAmharic;
  final Color bgColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  /// Colors for the edition chooser sheet — the reader paints its own shell,
  /// so the sheet cannot read them off the theme.
  final EditionSheetTheme sheetTheme;
  final AppStrings s;
  final VoidCallback onBack;
  final VoidCallback onFontSettings;
  final VoidCallback? onAudio;

  /// Opens search scoped to the book being read. Null disables the button
  /// rather than leaving it tappable and inert, which is what it was.
  final VoidCallback? onSearch;

  /// Opens the reference jump sheet.
  ///
  /// Deliberately its own button rather than sharing the magnifier with
  /// [onSearch]: one finds words anywhere, the other goes to a verse you can
  /// already name. Both arrived on the same icon and only one would have
  /// survived.
  final VoidCallback? onGoToReference;

  String get _label {
    final n    = chapterNumber ?? currentChapter + 1;
    final ch   = useGeez ? toGeez(n) : '$n';
    final book = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    return '$book · ${s.chapterAbbr} $ch';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Menu / back
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 22, color: mutedColor),
            onPressed: onBack,
          ),
          // Chapter dropdown (center)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChapterTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _label,
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: mutedColor),
                ],
              ),
            ),
          ),
          // Active edition — opens the chooser
          EditionChip(
            dense: true,
            foreground: accentColor,
            background: accentColor.withValues(alpha: 0.10),
            borderColor: accentColor.withValues(alpha: 0.28),
            sheetTheme: sheetTheme,
          ),
          const SizedBox(width: 2),
          if (onAudio != null)
            IconButton(
              icon: Icon(Icons.volume_up_rounded, size: 20, color: mutedColor),
              onPressed: onAudio,
            ),
          // Aa — opens font settings
          GestureDetector(
            onTap: onFontSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
          ),
          // Go to reference — type "ዘፍ 3:16" and jump straight there.
          if (onGoToReference != null)
            IconButton(
              icon: Icon(Icons.numbers_rounded, size: 20, color: mutedColor),
              onPressed: onGoToReference,
            ),
          // Search
          IconButton(
            icon: Icon(Icons.search_rounded, size: 20, color: mutedColor),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}
