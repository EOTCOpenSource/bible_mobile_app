import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({super.key});

  // These will come from the Bible data layer once wired up
  static const _verse = 'ቃልህ ለእግሬ መብራት ነው፤\nለመንገዴም ብርሃን ነው።';
  static const _reference = 'መዝሙረ ዳዊት ፻፲፱፥፻፭';

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tag row ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.dailyVerseTag,
                    style: AppTypography.amharicCaption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppIcons.ethiopianCross,
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.55),
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Verse text ─────────────────────────────────────────────────
            Text(
              _verse,
              style: AppTypography.amharicVerse.copyWith(
                color: AppColors.textOnDark,
                height: 1.9,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 18),
            // ── Reference + actions ────────────────────────────────────────
            Row(
              children: [
                Text(
                  _reference,
                  style: AppTypography.amharicLabel.copyWith(
                    color: AppColors.accent.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _IconAction(icon: Icons.share_outlined),
                const SizedBox(width: 2),
                _IconAction(icon: Icons.bookmark_border_rounded),
                const SizedBox(width: 2),
                _IconAction(icon: Icons.volume_up_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.textOnDark),
        ),
      ),
    );
  }
}
