import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../data/reading_plan.dart';
import '../../providers/reading_plan_providers.dart';

// Cycles through these colors for plan cards when more than one plan exists.
const _cardColors = [
  AppColors.primary,
  AppColors.newTestament,
  Color(0xFF3E5C3A),
  Color(0xFF7A4E2D),
];

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
        if (!isAuthenticated && !_dismissed)
          _AuthPrompt(
            onLogin: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            onDismiss: () => setState(() => _dismissed = true),
          )
        else
          _PlansList(dismissed: _dismissed),
      ],
    );
  }
}

class _PlansList extends ConsumerWidget {
  const _PlansList({required this.dismissed});

  final bool dismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(readingPlansProvider);

    return plansAsync.when(
      loading: () => const SizedBox(
        height: 148,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox(height: 148),
      data: (plans) {
        if (plans.isEmpty) return const SizedBox(height: 148);
        return SizedBox(
          height: 148,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plans.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ReadingPlanCard(
                plan: plans[i],
                color: _cardColors[i % _cardColors.length],
              ),
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

class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({required this.plan, required this.color});

  final ReadingPlan plan;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final progress = plan.durationInDays > 0
        ? plan.completedDays / plan.durationInDays
        : 0.0;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
            plan.name,
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
            s.daysCount(plan.durationInDays),
            style: AppTypography.amharicCaption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
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
