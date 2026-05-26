import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../data/reading_plan.dart';
import '../../providers/reading_plan_providers.dart';
import '../pages/reading_plans_screen.dart';

class ReadingPlansSection extends ConsumerStatefulWidget {
  const ReadingPlansSection({super.key});

  @override
  ConsumerState<ReadingPlansSection> createState() =>
      _ReadingPlansSectionState();
}

class _ReadingPlansSectionState extends ConsumerState<ReadingPlansSection> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final isAuthenticated =
        ref.watch(authStateProvider).status == AuthStatus.authenticated;

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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReadingPlansScreen()),
                ),
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
        if (!isAuthenticated && !_dismissed)
          _AuthPrompt(
            onLogin: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            onDismiss: () => setState(() => _dismissed = true),
          )
        else
          _PlansList(),
      ],
    );
  }
}

class _PlansList extends ConsumerWidget {
  const _PlansList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final plansAsync = ref.watch(readingPlansProvider);

    return plansAsync.when(
      loading: () => SizedBox(
        height: 176,
        child: Center(
          child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
        ),
      ),
      error: (e, _) => const SizedBox(height: 176),
      data: (plans) {
        if (plans.isEmpty) return const SizedBox(height: 176);
        return SizedBox(
          height: 176,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plans.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _ReadingPlanCard(plan: plans[i]),
            ),
          ),
        );
      },
    );
  }
}

class _AuthPrompt extends StatelessWidget {
  const _AuthPrompt({required this.onLogin, required this.onDismiss});

  final VoidCallback onLogin;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.readingPlansSyncPrompt,
                  style: AppTypography.amharicBody.copyWith(
                    color: c.textOnParchment,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: onLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        s.loginButton,
                        style: AppTypography.amharicLabel.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        s.continueWithoutAccount,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.textOnParchment.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carousel card: book cover on top, plan name + progress below.
class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({required this.plan});

  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final coverColor = testamentColor(plan.startBook);
    final pct = plan.durationInDays > 0
        ? (plan.completedDays / plan.durationInDays).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(coverColor: coverColor, width: 66, height: 98),
          const SizedBox(height: 6),
          Text(
            plan.name,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textOnParchment,
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            s.daysCount(plan.durationInDays),
            style: AppTypography.englishCaption.copyWith(
              color: c.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: c.parchmentDark,
              valueColor: AlwaysStoppedAnimation(coverColor),
            ),
          ),
        ],
      ),
    );
  }
}
