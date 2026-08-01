import 'package:bibleflutter/core/theme/app_color_scheme.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../widgets/optional_sign_in_page.dart';
import '../widgets/reading_preferences_page.dart';
import '../widgets/verse_actions_page.dart';
import '../widgets/welcome_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding({bool navigateToLogin = false}) {
    // 1. Mark onboarding as completed in Settings (persisted immediately to DB)
    final settings = Settings.of(context);
    Settings.update(context, settings.copyWith(hasSeenOnboarding: true));

    // 2. If navigateToLogin is true, push LoginScreen
    if (navigateToLogin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // If pushed onto navigator (e.g. from MeScreen), pop. Otherwise main.dart rebuild handles root.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final isLastPage = _currentPage == 3;

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with persistent Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandMark(size: 28),
                  TextButton(
                    onPressed: () => _finishOnboarding(),
                    child: Text(
                      s.onboardingSkip,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.accentDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  WelcomePage(s: s),
                  ReadingPreferencesPage(s: s),
                  VerseActionsPage(s: s),
                  OptionalSignInPage(
                    s: s,
                    onSignIn: () => _finishOnboarding(navigateToLogin: true),
                    onNotNow: () => _finishOnboarding(navigateToLogin: false),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar (Page Indicators & Next/Start controls)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      4,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? c.primary
                              : c.borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Finish Button (only on pages 0..2; page 3 has equal weight buttons)
                  if (!isLastPage)
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.onboardingNext,
                            style: AppTypography.amharicLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
