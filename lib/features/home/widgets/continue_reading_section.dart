import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ንባብ ቀጥል',
                style: AppTypography.amharicSubheading.copyWith(
                  color: AppColors.textOnParchment,
                ),
              ),
              const Spacer(),
              Text(
                '፵% ተጠናቅቋ',
                style: AppTypography.englishCaption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ContinueReadingCard(),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // ── Book cover ────────────────────────────────────────────────
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              AppIcons.ethiopianCross,
              style: TextStyle(color: AppColors.accent, fontSize: 24),
            ),
          ),
          const SizedBox(width: 14),
          // ── Book info ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'መጽሐፈ ነገሥት ቀዳማዊ',
                  style: AppTypography.amharicLabel.copyWith(
                    color: AppColors.textOnParchment,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1 Kings · Chapter 8',
                  style: AppTypography.englishCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.40,
                    minHeight: 6,
                    backgroundColor: AppColors.parchmentDark,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Arrow ─────────────────────────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
