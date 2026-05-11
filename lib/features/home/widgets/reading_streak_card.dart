import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_button.dart';

class ReadingStreakCard extends StatelessWidget {
  const ReadingStreakCard({super.key, required this.todayWeekday});

  /// 0 = Sunday … 6 = Saturday, as returned by Kenat.getWeekday()
  final int todayWeekday;

  // true = done, null = today, false = future
  List<bool?> get _status => List.generate(
        7,
        (i) => i < todayWeekday ? true : i == todayWeekday ? null : false,
      );

  static const _streakCount = 12; // placeholder until user data is wired

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final status = _status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: flame + streak count ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  '$_streakCount',
                  style: AppTypography.amharicSubheading.copyWith(
                    color: AppColors.textOnParchment,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  s.streakDaysSuffix,
                  style: AppTypography.amharicSubheading.copyWith(
                    color: AppColors.textOnParchment,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.streakConsecutiveLabel,
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Row 2: day circles ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = status[i];
                final isToday = done == null;
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? AppColors.primary
                            : done == true
                                ? AppColors.primaryLight
                                : AppColors.borderSubtle,
                        border: isToday
                            ? Border.all(color: AppColors.accent, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: done == true
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : isToday
                              ? const Icon(Icons.star_rounded, size: 12, color: AppColors.accent)
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.weekdayAbbr[i],
                      style: AppTypography.amharicCaption.copyWith(
                        fontSize: 9,
                        color: AppColors.textCaption,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            // ── Row 3: hint + CTA ──────────────────────────────────────────
            Row(
              children: [
                Text(
                  s.streakReadTodayHint,
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                PillButton(label: s.streakReadTodayBtn, onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
