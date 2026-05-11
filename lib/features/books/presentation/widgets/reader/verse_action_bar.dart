import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';

class VerseActionBar extends StatelessWidget {
  const VerseActionBar({
    super.key,
    required this.s,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.onBookmark,
    required this.onHighlight,
    required this.onCopy,
    required this.onShare,
    required this.onMore,
  });

  final AppStrings s;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onBookmark;
  final VoidCallback onHighlight;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
          VerseActionButton(icon: Icons.bookmark_add_outlined, label: s.verseBookmark,  textColor: textColor, onTap: onBookmark),
          VerseActionButton(icon: Icons.edit_outlined,         label: s.verseHighlight, textColor: textColor, onTap: onHighlight),
          VerseActionButton(icon: Icons.copy_rounded,          label: s.verseCopy,      textColor: textColor, onTap: onCopy),
          VerseActionButton(icon: Icons.share_outlined,        label: s.verseShare,     textColor: textColor, onTap: onShare),
          VerseActionButton(icon: Icons.more_horiz_rounded,    label: s.verseMore,      textColor: textColor, onTap: onMore),
        ],
      ),
    );
  }
}

class VerseActionButton extends StatelessWidget {
  const VerseActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 22),
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
