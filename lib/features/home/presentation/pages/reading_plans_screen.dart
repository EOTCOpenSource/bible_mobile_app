import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../data/reading_plan.dart';
import '../../providers/reading_plan_providers.dart';

class ReadingPlansScreen extends ConsumerWidget {
  const ReadingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final plansAsync = ref.watch(readingPlansProvider);

    return Scaffold(
      backgroundColor: c.parchment,
      appBar: AppBar(
        backgroundColor: c.parchment,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textOnParchment, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.readingPlansTitle,
          style: AppTypography.amharicSubheading.copyWith(color: c.textOnParchment),
        ),
      ),
      body: plansAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: c.primary),
        ),
        error: (e, s) => Center(
          child: Text(
            e.toString(),
            style: AppTypography.amharicBody.copyWith(color: c.textMuted),
          ),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Text(
                s.readingPlansTitle,
                style: AppTypography.amharicBody.copyWith(color: c.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: plans.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _PlanListCard(plan: plans[i]),
          );
        },
      ),
    );
  }
}

class _PlanListCard extends ConsumerWidget {
  const _PlanListCard({required this.plan});

  final ReadingPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final coverColor = testamentColor(plan.startBook);
    final pct = plan.durationInDays > 0
        ? (plan.completedDays / plan.durationInDays).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openReadingPlan(context, ref, plan),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              BookCover(coverColor: coverColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.textOnParchment,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.daysCount(plan.durationInDays),
                      style: AppTypography.englishCaption.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: c.parchmentDark,
                              valueColor: AlwaysStoppedAnimation(coverColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).round()}%',
                          style: AppTypography.englishCaption.copyWith(
                            color: coverColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: coverColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: coverColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
