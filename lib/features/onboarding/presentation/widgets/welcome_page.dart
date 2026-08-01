import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.s});

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/eotc.jpg', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            s.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicHeading.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textOnParchment,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Text(
              s.onboardingWelcomeCanonNote,
              textAlign: TextAlign.center,
              style: AppTypography.amharicBody.copyWith(
                fontSize: 15,
                color: c.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
