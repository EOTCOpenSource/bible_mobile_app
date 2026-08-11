import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class VerseActionBar extends StatelessWidget {
  const VerseActionBar({
    super.key,
    required this.s,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.isBookmarked,
    required this.highlightColor,
    required this.hasNote,
    required this.onBookmark,
    required this.onHighlight,
    required this.onNote,
    required this.onCopy,
    required this.onShare,
  });

  final AppStrings s;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final bool isBookmarked;
  final Color? highlightColor;
  final bool hasNote;
  final VoidCallback onBookmark;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: _ActionBtn(
              icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              label: s.verseBookmark,
              semanticLabel: isBookmarked ? s.semanticsBookmarkRemove : s.semanticsBookmarkAdd,
              selected: isBookmarked,
              textColor: isBookmarked ? context.colors.primary : textColor,
              onTap: onBookmark,
            ),
          ),
          Flexible(
            child: _ActionBtn(
              icon: Icons.format_color_fill_rounded,
              label: s.verseHighlight,
              semanticLabel: highlightColor != null ? s.semanticsHighlightActive : s.semanticsHighlightAdd,
              selected: highlightColor != null,
              textColor: highlightColor ?? textColor,
              onTap: onHighlight,
              dot: highlightColor,
            ),
          ),
          Flexible(
            child: _ActionBtn(
              icon: hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
              label: s.verseNote,
              semanticLabel: hasNote ? s.semanticsNoteEdit : s.semanticsNoteAdd,
              selected: hasNote,
              textColor: hasNote ? context.colors.accentDeep : textColor,
              onTap: onNote,
            ),
          ),
          Flexible(
            child: _ActionBtn(
              icon: Icons.copy_rounded,
              label: s.verseCopy,
              semanticLabel: s.verseCopy,
              textColor: textColor,
              onTap: onCopy,
            ),
          ),
          Flexible(
            child: _ActionBtn(
              icon: Icons.share_outlined,
              label: s.verseShare,
              semanticLabel: s.verseShare,
              textColor: textColor,
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.textColor,
    required this.onTap,
    this.selected,
    this.dot,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color textColor;
  final VoidCallback onTap;
  final bool? selected;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: textColor, size: 22),
                      if (dot != null)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dot,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.amharicCaption.copyWith(
                        fontSize: 10,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
