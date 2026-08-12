import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                // Menu / back
                Semantics(
                  button: true,
                  label: s.semanticsMenuBtn,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                    icon: ExcludeSemantics(
                      child: Icon(Icons.menu_rounded, size: 22, color: mutedColor),
                    ),
                    onPressed: onBack,
                  ),
                ),
                // Active edition — opens the chooser
                Flexible(
                  child: EditionChip(
                    dense: true,
                    foreground: accentColor,
                    background: accentColor.withValues(alpha: 0.10),
                    borderColor: accentColor.withValues(alpha: 0.28),
                    sheetTheme: sheetTheme,
                  ),
                ),
                const SizedBox(width: 4),
                if (onAudio != null)
                  Semantics(
                    button: true,
                    label: s.semanticsAudioBtn,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 48),
                      icon: ExcludeSemantics(
                        child: Icon(Icons.volume_up_rounded, size: 20, color: mutedColor),
                      ),
                      onPressed: onAudio,
                    ),
                  ),
                // Aa — opens font settings
                Semantics(
                  button: true,
                  label: s.semanticsFontSettingsBtn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFontSettings,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 48,
                      ),
                      child: Center(
                        child: ExcludeSemantics(
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
                    ),
                  ),
                ),
                // Go to reference — type "ዘፍ 3:16" and jump straight there.
                if (onGoToReference != null)
                  Semantics(
                    button: true,
                    label: s.semanticsRefJumpBtn,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 48),
                      icon: ExcludeSemantics(
                        child: Icon(Icons.numbers_rounded, size: 20, color: mutedColor),
                      ),
                      onPressed: onGoToReference,
                    ),
                  ),
                // Search
                Semantics(
                  button: true,
                  label: s.semanticsSearchBtn,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 48),
                    icon: ExcludeSemantics(
                      child: Icon(Icons.search_rounded, size: 20, color: mutedColor),
                    ),
                    onPressed: onSearch,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
