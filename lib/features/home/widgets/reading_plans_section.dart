import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ReadingPlansSection extends StatelessWidget {
  const ReadingPlansSection({super.key});

  static const _plans = [
    _PlanData(
      titleAm: 'መጽሐፈ ዘፍጥረት',
      daysLabel: '30 ቀናት',
      totalDays: 30,
      completedDays: 12,
      color: AppColors.primary,
    ),
    _PlanData(
      titleAm: 'ወንጌለ ዮሐንስ',
      daysLabel: '21 ቀናት',
      totalDays: 21,
      completedDays: 5,
      color: AppColors.newTestament,
    ),
    _PlanData(
      titleAm: 'መዝሙረ ዳዊት',
      daysLabel: '45 ቀናት',
      totalDays: 45,
      completedDays: 0,
      color: Color(0xFF3E5C3A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                'የንባብ ዕቅዶ',
                style: AppTypography.amharicSubheading.copyWith(
                  color: AppColors.textOnParchment,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'ሁሉንም ይመልከቱ',
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.primary,
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
            itemBuilder: (_, i) => Padding(
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
  final String daysLabel;
  final int totalDays;
  final int completedDays;
  final Color color;

  const _PlanData({
    required this.titleAm,
    required this.daysLabel,
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
            child: const Text(
              AppIcons.ethiopianCross,
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
          ),
          const Spacer(),
          Text(
            plan.titleAm,
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
            plan.daysLabel,
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
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
