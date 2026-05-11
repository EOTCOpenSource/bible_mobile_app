import 'package:flutter/material.dart';
import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Ethiopian Orthodox Cross brand mark with optional label.
///
/// Usage:
///   BrandMark()                  // cross only, default size
///   BrandMark(size: 48)          // larger cross
///   BrandMark(showLabel: true)   // cross + "መጽሐፍ ቅዱስ" below
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 32,
    this.color = AppColors.accent,
    this.showLabel = false,
  });

  final double size;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final cross = Text(
      AppIcons.ethiopianCross,
      style: TextStyle(
        fontSize: size,
        color: color,
        height: 1,
        fontFamily: 'Segoe UI Symbol', // Windows fallback; Noto covers others
      ),
    );

    if (!showLabel) return cross;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        cross,
        const SizedBox(height: 6),
        Text(
          'መጽሐፍ ቅዱስ',
          style: AppTypography.amharicLabel.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Small coloured badge indicating Old or New Testament.
class TestamentBadge extends StatelessWidget {
  const TestamentBadge({super.key, required this.testament});

  final String testament; // 'old' | 'new'

  @override
  Widget build(BuildContext context) {
    final isOld = testament.toLowerCase() == 'old';
    final bg = isOld ? AppColors.oldTestament : AppColors.newTestament;
    final label = isOld ? 'OT' : 'NT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.englishCaption.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Ornamental gold divider with the Ethiopian cross centred.
class LiturgicalDivider extends StatelessWidget {
  const LiturgicalDivider({super.key, this.color = AppColors.divider});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            AppIcons.ethiopianCross,
            style: TextStyle(color: AppColors.accentDeep, fontSize: 14),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}
