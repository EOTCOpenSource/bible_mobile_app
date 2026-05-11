import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class ChapterNavBar extends StatelessWidget {
  const ChapterNavBar({
    super.key,
    required this.currentChapter,
    required this.totalChapters,
    required this.isDark,
    required this.useGeez,
    required this.s,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.onPrev,
    required this.onNext,
  });

  final int currentChapter;
  final int totalChapters;
  final bool isDark;
  final bool useGeez;
  final AppStrings s;
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  String _ch(int idx) {
    final n = idx + 1;
    return '${s.chapterAbbr} ${useGeez ? toGeez(n) : n}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentChapter > 0;
    final hasNext = currentChapter < totalChapters - 1;
    final total   = useGeez ? toGeez(totalChapters) : '$totalChapters';

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          ChapterNavArrow(
            icon: Icons.chevron_left_rounded,
            label: hasPrev ? _ch(currentChapter - 1) : '',
            enabled: hasPrev,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onPrev,
          ),
          Expanded(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '${_ch(currentChapter)}  ·  $total',
                  style: TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
          ChapterNavArrow(
            icon: Icons.chevron_right_rounded,
            label: hasNext ? _ch(currentChapter + 1) : '',
            enabled: hasNext,
            isNext: true,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class ChapterNavArrow extends StatelessWidget {
  const ChapterNavArrow({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
    this.isNext = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool isNext;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? textColor : mutedColor.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNext) Icon(icon, color: color, size: 22),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 11,
                  color: color,
                ),
              ),
            if (isNext) Icon(icon, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
