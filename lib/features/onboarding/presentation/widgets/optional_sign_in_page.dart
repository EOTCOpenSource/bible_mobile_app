import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';

class OptionalSignInPage extends StatelessWidget {
  const OptionalSignInPage({
    super.key,
    required this.s,
    required this.onSignIn,
    required this.onNotNow,
  });

  final AppStrings s;
  final VoidCallback onSignIn;
  final VoidCallback onNotNow;

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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_sync_rounded, size: 64, color: c.primary),
          ),
          const SizedBox(height: 28),
          Text(
            s.onboardingSignInTitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicHeading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textOnParchment,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Text(
              s.onboardingSignInSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.amharicBody.copyWith(
                fontSize: 14,
                color: c.textMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.onboardingSignInBtn,
                      style: AppTypography.amharicLabel.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNotNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.onboardingNotNowBtn,
                      style: AppTypography.amharicLabel.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
