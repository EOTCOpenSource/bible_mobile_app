import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../books/data/reading_date.dart';
import '../../../books/providers/reading_progress_providers.dart';

class ReadingStreakCard extends ConsumerWidget {
  const ReadingStreakCard({
    super.key,
    required this.todayWeekday,
    required this.onReadToday,
  });

  /// Raw value from Kenat.getWeekday(): 0 = Sunday … 6 = Saturday
  final int todayWeekday;
  final VoidCallback onReadToday;

  // Remap to Monday-first display index (0 = Mon … 6 = Sun)
  int _todayIndex() => (todayWeekday + 6) % 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;
    final streakAsync = ref.watch(readingStreakStateProvider);
    final streakCount = streakAsync.value?.currentStreak ?? 0;
    final qualifiedToday = streakAsync.value?.lastQualifiedDate ==
        ReadingDate.todayIso();

    final streakDisplay =
        useGeez ? toGeez(streakCount) : '$streakCount';

    final todayIdx = _todayIndex();
    final status = List<bool?>.generate(7, (i) {
      if (i < todayIdx) return true;
      if (i > todayIdx) return false;
      return qualifiedToday ? true : null;
    });

    final isAm = s is AmStrings;
    final dayNames = isAm ? DaysOfWeek.amharic : DaysOfWeek.english;
    String dayAbbr(int i) {
      final name = dayNames[(i + 1) % 7];
      return name.length <= 3 ? name : name.substring(0, 3);
    }

    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.borderSubtle),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  streakDisplay,
                  style: AppTypography.amharicSubheading.copyWith(
                    color: c.textOnParchment,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  s.streakDaysSuffix,
                  style: AppTypography.amharicSubheading.copyWith(
                    color: c.textOnParchment,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.streakConsecutiveLabel,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = status[i];
                final isToday = i == todayIdx;
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? c.primary
                            : done == true
                                ? c.primaryLight
                                : c.borderSubtle,
                        border: isToday && !qualifiedToday
                            ? Border.all(color: c.accent, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: done == true
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : isToday && !qualifiedToday
                              ? Icon(Icons.star_rounded, size: 12, color: c.accent)
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayAbbr(i),
                      style: AppTypography.amharicCaption.copyWith(
                        fontSize: 9,
                        color: c.textCaption,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            Divider(color: c.borderSubtle, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  s.streakReadTodayHint,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                  ),
                ),
                const Spacer(),
                PillButton(label: s.streakReadTodayBtn, onTap: onReadToday),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
