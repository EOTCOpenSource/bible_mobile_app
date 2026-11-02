import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

class VerseActionsPage extends StatelessWidget {
  const VerseActionsPage({super.key, required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            s.onboardingActionsTitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicHeading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textOnParchment,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.onboardingActionsSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicCaption.copyWith(
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.onboardingSampleVerseNumber,
                        style: AppTypography.amharicLabel.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.onboardingSampleVerseText,
                          style: AppTypography.amharicBody.copyWith(
                            fontSize: 15,
                            color: c.textOnParchment,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.parchment,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionBarItemMock(
                        icon: Icons.border_color_rounded,
                        label: s.verseHighlight,
                        color: c.accentDeep,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.edit_note_rounded,
                        label: s.verseNote,
                        color: c.primary,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.bookmark_rounded,
                        label: s.verseBookmark,
                        color: c.accentDeep,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.share_rounded,
                        label: s.verseShare,
                        color: c.textOnParchment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ActionBarItemMock extends StatelessWidget {
  const _ActionBarItemMock({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
