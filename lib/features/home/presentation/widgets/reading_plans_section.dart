import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ReadingPlansSection extends StatelessWidget {
  const ReadingPlansSection({super.key});

  // Titles are data — will come from the data layer once wired.
  // Using Amharic names directly here since they're proper nouns.
  static const _plans = [
    _PlanData(
      titleAm: 'መጽሐፈ ዘፍጥረት',
      titleEn: 'Genesis',
      totalDays: 30,
      completedDays: 12,
      color: AppColors.primary,
    ),
    _PlanData(
      titleAm: 'ወንጌለ ዮሐንስ',
      titleEn: 'Gospel of John',
      totalDays: 21,
      completedDays: 5,
      color: AppColors.newTestament,
    ),
    _PlanData(
      titleAm: 'መዝሙረ ዳዊት',
      titleEn: 'Psalms',
      totalDays: 45,
      completedDays: 0,
      color: Color(0xFF3E5C3A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                s.readingPlansTitle,
                style: AppTypography.amharicSubheading.copyWith(
                  color: c.textOnParchment,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  s.viewAll,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plans.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ReadingPlanCard(plan: _plans[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String titleAm;
  final String titleEn;
  final int totalDays;
  final int completedDays;
  final Color color;

  const _PlanData({
    required this.titleAm,
    required this.titleEn,
    required this.totalDays,
    required this.completedDays,
    required this.color,
  });
}

class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({required this.plan});
  final _PlanData plan;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final isAmharic = s is AmStrings;
    final progress = plan.completedDays / plan.totalDays;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: plan.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              AppIcons.ethiopianCross,
              style: TextStyle(color: context.colors.accent, fontSize: 16),
            ),
          ),
          const Spacer(),
          Text(
            isAmharic ? plan.titleAm : plan.titleEn,
            style: AppTypography.amharicLabel.copyWith(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            s.daysCount(plan.totalDays),
            style: AppTypography.amharicCaption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(context.colors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
