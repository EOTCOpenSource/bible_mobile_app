import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/data/reading_date.dart';
import '../../../books/providers/reading_progress_providers.dart';
import '../../data/streak_month.dart';

/// The full reading-streak view: current run, this week, lifetime totals, the
/// Ethiopian month calendar and the rest-day balance.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key, required this.onReadToday});

  /// Sends the user to the books tab. The screen pops itself first, so the
  /// callback never fires against a route that is about to go away.
  final VoidCallback onReadToday;

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  /// The Ethiopian month on show. Starts on today's and moves with the arrows,
  /// so past streaks stay reachable without leaving the page.
  int? _year;
  int? _month;

  void _step(({int year, int month}) to) =>
      setState(() {
        _year = to.year;
        _month = to.month;
      });

  /// Monday-first dates for the week containing today.
  List<DateTime> _thisWeek() {
    final today = ReadingDate.todayLocal();
    // DateTime.weekday is 1 = Monday … 7 = Sunday.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;
    final amharic = s is AmStrings;

    final streak = ref.watch(readingStreakStateProvider).value;
    final totals = ref.watch(readingTotalsProvider).value;

    final todayEt = Kenat.now().getEthiopian();
    final year = _year ?? todayEt['year'] as int;
    final month = _month ?? todayEt['month'] as int;

    // The month is built twice: once with no read days just to learn its span,
    // then again once the log for that span has loaded. Cheap — it is at most
    // 30 date conversions — and it keeps the query keyed to real month bounds
    // instead of a guessed 31-day window.
    final skeleton = StreakMonth.of(
      year: year,
      month: month,
      readDays: const {},
      amharic: amharic,
    );
    final readDays = ref
            .watch(readDaysInRangeProvider(
                (from: skeleton.firstIso, to: skeleton.lastIso)))
            .value ??
        const <String>{};
    final shownMonth = StreakMonth.of(
      year: year,
      month: month,
      readDays: readDays,
      amharic: amharic,
    );

    // The header always describes today, never the month being browsed. Its
    // window is the week itself: a Mon–Sun week straddles the month boundary
    // twice a year, and reusing the month's range would blank those days out.
    final week = _thisWeek();
    final weekDays = ref
            .watch(readDaysInRangeProvider((
              from: ReadingDate.toIsoDate(week.first),
              to: ReadingDate.toIsoDate(week.last),
            )))
            .value ??
        const <String>{};

    String fmt(int n) => useGeez ? toGeez(n) : '$n';

    return Scaffold(
      backgroundColor: c.parchment,
      body: Column(
        children: [
          _Header(
            streakCount: streak?.currentStreak ?? 0,
            week: week,
            readDays: weekDays,
            format: fmt,
            amharic: amharic,
            colors: c,
          ),
          // Everything below the header is fixed except the calendar, which
          // takes whatever is left. The page is meant to be read at a glance,
          // so it fits the screen rather than scrolling — and letting the grid
          // absorb the slack is what keeps that true from a small phone to a
          // tall one without hand-tuned heights per device.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  _StatsRow(
                    longest: fmt(streak?.longestStreak ?? 0),
                    totalDays: fmt(totals?.totalDays ?? 0),
                    chapters: fmt(totals?.totalChapters ?? 0),
                    colors: c,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _MonthCalendar(
                      month: shownMonth,
                      format: fmt,
                      colors: c,
                      onPrevious: () => _step(shownMonth.previous),
                      onNext: shownMonth.isCurrentMonth
                          ? null
                          : () => _step(shownMonth.next),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FreezeCard(credits: streak?.freezeCredits ?? 0, colors: c),
                  const SizedBox(height: 12),
                  _ReadTodayButton(
                    alreadyRead:
                        streak?.lastQualifiedDate == ReadingDate.todayIso(),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onReadToday();
                    },
                    colors: c,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.streakCount,
    required this.week,
    required this.readDays,
    required this.format,
    required this.amharic,
    required this.colors,
  });

  final int streakCount;

  /// Monday-first dates for the week containing today.
  final List<DateTime> week;
  final Set<String> readDays;
  final String Function(int) format;
  final bool amharic;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);
    final todayIso = ReadingDate.todayIso();
    final dayNames = amharic ? DaysOfWeek.amharic : DaysOfWeek.english;

    return Container(
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The same soft disc the daily verse card uses, so the two maroon
          // surfaces read as one family.
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CircleBackButton(colors: c),
                      Expanded(
                        child: Text(
                          s.streakPageTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.amharicLabel.copyWith(
                            color: c.textOnDark.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Balances the back button so the title stays centred.
                      const SizedBox(width: 34),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Flame and count share a line: stacked, they cost about
                  // 50dp of pure header for one number.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      Text(
                        format(streakCount),
                        style: AppTypography.amharicHeading.copyWith(
                          color: c.textOnDark,
                          fontSize: 40,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    s.streakDayStreakLabel,
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.accent,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final date in week)
                        _WeekDot(
                          label: dayNames[date.weekday % 7],
                          read: readDays.contains(ReadingDate.toIsoDate(date)),
                          isToday: ReadingDate.toIsoDate(date) == todayIso,
                          colors: c,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.chevron_left_rounded,
            color: colors.textOnDark,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.label,
    required this.read,
    required this.isToday,
    required this.colors,
  });

  final String label;
  final bool read;
  final bool isToday;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: read ? c.accent : Colors.white.withValues(alpha: 0.10),
            border: isToday && !read
                ? Border.all(color: c.accent.withValues(alpha: 0.7), width: 1.6)
                : null,
          ),
          alignment: Alignment.center,
          child: read
              ? Icon(Icons.check_rounded, size: 16, color: c.primaryDark)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label.length <= 3 ? label : label.substring(0, 3),
          style: AppTypography.amharicCaption.copyWith(
            color: c.textOnDark.withValues(alpha: 0.65),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.longest,
    required this.totalDays,
    required this.chapters,
    required this.colors,
  });

  final String longest;
  final String totalDays;
  final String chapters;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
              value: longest, label: s.streakStatLongest, colors: colors),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
              value: totalDays, label: s.streakStatTotalDays, colors: colors),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
              value: chapters, label: s.streakStatChapters, colors: colors),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.colors,
  });

  final String value;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicCaption
                .copyWith(color: c.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Month calendar ───────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.format,
    required this.colors,
    required this.onPrevious,
    required this.onNext,
  });

  final StreakMonth month;
  final String Function(int) format;
  final AppColorScheme colors;
  final VoidCallback onPrevious;

  /// Null on the current month — there is nothing ahead to look at.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    month.name,
                    style: AppTypography.amharicSubheading
                        .copyWith(color: c.textOnParchment, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Progress is against days that have happened, so the
                    // current month is not scored on days still to come.
                    '${s.streakMonthProgress(format(month.readCount), format(month.elapsedDays))}'
                    '  ·  ${format(month.year)}',
                    style: AppTypography.amharicCaption
                        .copyWith(color: c.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _MonthArrow(
              icon: Icons.chevron_left_rounded,
              onTap: onPrevious,
              colors: c,
            ),
            const SizedBox(width: 8),
            _MonthArrow(
              icon: Icons.chevron_right_rounded,
              onTap: onNext,
              colors: c,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final label in month.weekdayHeaders)
              Expanded(
                child: Text(
                  // Amharic weekday names are long; two glyphs is enough to
                  // tell the columns apart at this width.
                  label.characters.take(2).toString(),
                  textAlign: TextAlign.center,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textCaption,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // The grid fills the space the page has left over instead of claiming
        // a fixed cell size, so a 5-row month and a 6-row month both fit
        // without scrolling and without squashing anything below.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 5.0;
              final cells = month.leadingBlanks + month.days.length;
              final rows = (cells / 7).ceil();

              final cellWidth = (constraints.maxWidth - spacing * 6) / 7;
              final cellHeight =
                  (constraints.maxHeight - spacing * (rows - 1)) / rows;

              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  // Never taller than square: on a roomy screen the cells stop
                  // stretching into lozenges and the grid just sits higher.
                  childAspectRatio: cellWidth / cellHeight.clamp(1.0, cellWidth),
                ),
                itemBuilder: (_, i) {
                  // Blanks hold day 1 under its real weekday column.
                  if (i < month.leadingBlanks) return const SizedBox.shrink();
                  return _DayCell(
                    day: month.days[i - month.leadingBlanks],
                    format: format,
                    colors: c,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final enabled = onTap != null;
    return Material(
      color: enabled ? c.surface : c.surface.withValues(alpha: 0.5),
      shape: CircleBorder(
        side: BorderSide(
          color: enabled ? c.borderSubtle : c.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? c.textOnParchment : c.textCaption.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.format,
    required this.colors,
  });

  final StreakDay day;
  final String Function(int) format;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;

    final (Color bg, Color fg, FontWeight weight) = switch (day) {
      _ when day.isToday => (c.primary, c.accent, FontWeight.w700),
      _ when day.isRead => (
          c.accent.withValues(alpha: 0.45),
          c.primary,
          FontWeight.w700,
        ),
      _ when day.isFuture => (
          Colors.transparent,
          c.textMuted.withValues(alpha: 0.35),
          FontWeight.w400,
        ),
      _ => (Colors.transparent, c.textMuted, FontWeight.w400),
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: bg == Colors.transparent
            ? Border.all(color: c.borderSubtle.withValues(alpha: 0.6))
            : null,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            format(day.day),
            style: AppTypography.amharicCaption.copyWith(
              color: fg,
              fontSize: 13,
              fontWeight: weight,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Freeze card ──────────────────────────────────────────────────────────────

class _FreezeCard extends StatelessWidget {
  const _FreezeCard({required this.credits, required this.colors});

  final int credits;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);
    final has = credits > 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.borderSubtle),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.ac_unit_rounded,
              size: 18,
              color: has ? c.primary : c.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has
                      ? s.streakFreezeTitle('$credits')
                      : s.streakFreezeEmptyTitle,
                  style: AppTypography.amharicLabel
                      .copyWith(color: c.textOnParchment, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  has ? s.streakFreezeSubtitle : s.streakFreezeEmptySubtitle,
                  style: AppTypography.amharicCaption
                      .copyWith(color: c.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom action ────────────────────────────────────────────────────────────

class _ReadTodayButton extends StatelessWidget {
  const _ReadTodayButton({
    required this.alreadyRead,
    required this.onTap,
    required this.colors,
  });

  final bool alreadyRead;
  final VoidCallback onTap;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);

    if (alreadyRead) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primary.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Text(
              s.streakTodayDone,
              style: AppTypography.amharicLabel
                  .copyWith(color: c.primary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              s.streakReadTodayBtn,
              style: AppTypography.amharicLabel
                  .copyWith(color: c.accent, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
