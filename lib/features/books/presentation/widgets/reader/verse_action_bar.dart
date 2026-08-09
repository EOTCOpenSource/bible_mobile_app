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
    this.onCrossRef,
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
  final VoidCallback? onCrossRef;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    Widget rowContent = Row(
      mainAxisAlignment: isCompact ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
      mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (onCrossRef != null)
          _ActionBtn(
            icon: Icons.alt_route_rounded,
            label: s.verseCrossReferences,
            textColor: textColor,
            onTap: onCrossRef!,
          ),
        _ActionBtn(
          icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
          label: s.verseBookmark,
          textColor: isBookmarked ? context.colors.primary : textColor,
          onTap: onBookmark,
        ),
        _ActionBtn(
          icon: Icons.format_color_fill_rounded,
          label: s.verseHighlight,
          textColor: highlightColor ?? textColor,
          onTap: onHighlight,
          dot: highlightColor,
        ),
        _ActionBtn(
          icon: hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
          label: s.verseNote,
          textColor: hasNote ? context.colors.accentDeep : textColor,
          onTap: onNote,
        ),
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: s.verseCopy,
          textColor: textColor,
          onTap: onCopy,
        ),
        _ActionBtn(
          icon: Icons.share_outlined,
          label: s.verseShare,
          textColor: textColor,
          onTap: onShare,
        ),
      ],
    );

    if (isCompact) {
      rowContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: rowContent,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
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
          child: rowContent,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
    this.dot,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              label,
              style: AppTypography.amharicCaption.copyWith(
                fontSize: 10,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
