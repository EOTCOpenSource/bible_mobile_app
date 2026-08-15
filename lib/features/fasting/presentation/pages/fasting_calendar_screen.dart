import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/fasts.dart';

class FastingCalendarScreen extends StatefulWidget {
  const FastingCalendarScreen({super.key});

  @override
  State<FastingCalendarScreen> createState() => _FastingCalendarScreenState();
}

class _FastingCalendarScreenState extends State<FastingCalendarScreen> {
  late int _year;
  late int _month;
  EthiopianDate? _selectedDate;

  static const _amharicMonths = [
    'መስከረም',
    'ጥቅምት',
    'ኅዳር',
    'ታኅሣሥ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜን',
  ];

  static const _englishMonths = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  static const _amharicWeekdays = ['እሑድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ'];
  static const _englishWeekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final today = EthiopianDate.now();
    _year = today.year;
    _month = today.month;
    _selectedDate = today;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 13;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 13) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  Color _fastTypeColor(FastType type, AppColorScheme c) {
    return switch (type) {
      FastType.abiyTsom => const Color(0xFF7B1FA2), // Purple
      FastType.tsomeNebiyat => const Color(0xFF1976D2), // Blue
      FastType.tsomeFilseta => const Color(0xFFF57C00), // Amber/Orange
      FastType.tsomeHawariyat => const Color(0xFF388E3C), // Green
      FastType.tsomeNenewe => const Color(0xFFC2185B), // Crimson
      FastType.tsomeGahad => const Color(0xFFD32F2F), // Red
      FastType.tsomeDihnet => const Color(0xFF0097A7), // Teal
    };
  }

  int _daysInMonth(int year, int month) {
    if (month < 13) return 30;
    return (year % 4 == 3) ? 6 : 5;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final isAmharic = s is AmStrings;
    final settings = Settings.of(context);
    final useGeez = settings.useGeezNumbers;

    String numStr(int n) => useGeez ? toGeez(n) : '$n';

    final monthName = isAmharic
        ? _amharicMonths[_month - 1]
        : _englishMonths[_month - 1];
    final yearStr = numStr(_year);

    final firstDayWeekday =
        Kenat.fromEthiopian(_year, _month, 1).getWeekday(); // 0 = Sun
    final totalDays = _daysInMonth(_year, _month);
    final today = EthiopianDate.now();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          s.fastingCalendarTitle,
          style: AppTypography.amharicHeading.copyWith(
            color: c.textOnParchment,
            fontSize: 18,
          ),
        ),
        backgroundColor: c.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textOnParchment),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Month Header & Navigation
            Container(
              color: c.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: c.textOnParchment, size: 28),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    '$monthName $yearStr',
                    style: AppTypography.amharicHeading.copyWith(
                      color: c.textOnParchment,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: c.textOnParchment, size: 28),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Weekday Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: List.generate(7, (index) {
                  final dayLabel = isAmharic
                      ? _amharicWeekdays[index]
                      : _englishWeekdays[index];
                  return Expanded(
                    child: Center(
                      child: Text(
                        dayLabel,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Days Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firstDayWeekday + totalDays,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  if (index < firstDayWeekday) {
                    return const SizedBox.shrink();
                  }

                  final dayNum = index - firstDayWeekday + 1;
                  final date = EthiopianDate(_year, _month, dayNum);
                  final status = fastStatusFor(date);
                  final isToday = date == today;
                  final isSelected = _selectedDate == date;

                  Color? dayBgColor;
                  Color? dotColor;

                  if (status.isFasting && status.active.isNotEmpty) {
                    final primary = status.active.firstWhere(
                      (p) => !p.isWeekly,
                      orElse: () => status.active.first,
                    );
                    dotColor = _fastTypeColor(primary.type, c);
                    dayBgColor = dotColor.withValues(alpha: 0.15);
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.accent.withValues(alpha: 0.25)
                            : (dayBgColor ?? c.surface),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? c.accent
                              : (isToday ? c.primary : c.borderSubtle),
                          width: isSelected || isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            numStr(dayNum),
                            style: AppTypography.amharicSubheading.copyWith(
                              color: isSelected
                                  ? c.accent
                                  : (isToday ? c.primary : c.textOnParchment),
                              fontWeight:
                                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          if (dotColor != null) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),



            const SizedBox(height: 16),

            // Selected Day Details Card
            if (_selectedDate != null) _buildSelectedDayDetails(context, _selectedDate!, c, s, isAmharic, useGeez),

            const SizedBox(height: 16),

            // Legend
            _buildLegend(context, c, s, isAmharic),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetails(
    BuildContext context,
    EthiopianDate date,
    AppColorScheme c,
    AppStrings s,
    bool isAmharic,
    bool useGeez,
  ) {
    final status = fastStatusFor(date);
    String numStr(int n) => useGeez ? toGeez(n) : '$n';
    final monthName = isAmharic
        ? _amharicMonths[date.month - 1]
        : _englishMonths[date.month - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.isFasting ? Icons.restaurant : Icons.wb_sunny_outlined,
                color: status.isFasting ? c.accent : c.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$monthName ${numStr(date.day)}፣ ${numStr(date.year)}',
                style: AppTypography.amharicSubheading.copyWith(
                  color: c.textOnParchment,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.isFasting
                      ? c.accent.withValues(alpha: 0.15)
                      : c.borderSubtle.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.isFasting ? s.fastingIsFast : s.fastingNotFast,
                  style: TextStyle(
                    color: status.isFasting ? c.accent : c.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (status.isFasting) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...status.active.map((p) {
              final color = _fastTypeColor(p.type, c);
              final name = isAmharic ? p.nameAmharic : p.nameEnglish;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: AppTypography.amharicSubheading.copyWith(
                        color: c.textOnParchment,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    AppColorScheme c,
    AppStrings s,
    bool isAmharic,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.fastingLegendTitle,
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: FastType.values.map((type) {
              final color = _fastTypeColor(type, c);
              final name = isAmharic ? type.nameAmharic : type.nameEnglish;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textOnParchment,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
