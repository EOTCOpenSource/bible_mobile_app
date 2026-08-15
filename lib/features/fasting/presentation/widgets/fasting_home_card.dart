import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/fasts.dart';
import '../pages/fasting_calendar_screen.dart';

/// Compact card displayed on [HomeTab] showing today's Ethiopian fasting status.
class FastingHomeCard extends StatelessWidget {
  const FastingHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final isAmharic = s is AmStrings;
    final settings = Settings.of(context);
    final useGeez = settings.useGeezNumbers;

    final today = EthiopianDate.now();
    final status = fastStatusFor(today);

    String numStr(int n) => useGeez ? toGeez(n) : '$n';

    final String statusTitle;
    final String statusSubtitle;
    final Color badgeBg;
    final Color badgeFg;

    if (status.isFasting) {
      final primary = status.active.firstWhere(
        (p) => !p.isWeekly,
        orElse: () => status.active.first,
      );
      final fastName = isAmharic ? primary.nameAmharic : primary.nameEnglish;
      statusTitle = s.fastingIsFast;
      final remainingStr = s.fastingDaysRemaining(numStr(status.daysRemaining ?? 1));
      statusSubtitle = '$fastName ($remainingStr)';
      badgeBg = c.accent.withValues(alpha: 0.15);
      badgeFg = c.accent;
    } else {
      statusTitle = s.fastingNotFast;
      if (status.next != null && status.daysRemaining != null) {
        final nextName = isAmharic ? status.next!.nameAmharic : status.next!.nameEnglish;
        final startsInStr = s.fastingStartsIn(numStr(status.daysRemaining!));
        statusSubtitle = '${s.fastingNextFast} — $nextName $startsInStr';
      } else {
        statusSubtitle = '';
      }
      badgeBg = c.borderSubtle.withValues(alpha: 0.3);
      badgeFg = c.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FastingCalendarScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    status.isFasting ? Icons.restaurant : Icons.calendar_today_rounded,
                    color: badgeFg,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            statusTitle,
                            style: AppTypography.amharicSubheading.copyWith(
                              color: c.textOnParchment,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (status.isFasting)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isAmharic ? 'ጾም' : 'FAST',
                                style: TextStyle(
                                  color: c.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (statusSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusSubtitle,
                          style: AppTypography.amharicCaption.copyWith(
                            color: c.textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: c.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
