import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ContinueReadingSection extends StatelessWidget {
  const ContinueReadingSection({super.key});

  static const _progressPercent = 40; // placeholder until data layer is wired

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
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
                s.continueReadingTitle,
                style: AppTypography.amharicSubheading.copyWith(
                  color: c.textOnParchment,
                ),
              ),
              const Spacer(),
              Text(
                s.completedPercent(_progressPercent),
                style: AppTypography.englishCaption.copyWith(
                  color: c.primary,
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderSubtle),
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
              gradient: LinearGradient(
                colors: [c.primaryDark, c.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              AppIcons.ethiopianCross,
              style: TextStyle(color: c.accent, fontSize: 24),
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
                    color: c.textOnParchment,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1 Kings · Chapter 8',
                  style: AppTypography.englishCaption.copyWith(
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.40,
                    minHeight: 6,
                    backgroundColor: c.parchmentDark,
                    valueColor: AlwaysStoppedAnimation(c.primary),
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
              color: c.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: c.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
