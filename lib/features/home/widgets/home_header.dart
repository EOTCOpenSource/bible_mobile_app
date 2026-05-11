import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'እንኳን ደህና\nመጡ',
                  style: AppTypography.amharicDisplay.copyWith(
                    color: AppColors.textOnParchment,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _Avatar(letter: 'ን'),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.amharicSubheading.copyWith(
          color: AppColors.textOnDark,
          fontSize: 20,
        ),
      ),
    );
  }
}
