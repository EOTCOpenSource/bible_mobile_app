import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../books/presentation/widgets/reader/constants.dart';

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
                  _WelcomePage(s: s),
                  _ReadingPreferencesPage(s: s),
                  _VerseActionsPage(s: s),
                  _OptionalSignInPage(
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

// ── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.s});
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
          // Container(
          //   padding: const EdgeInsets.all(28),
          //   decoration: BoxDecoration(
          //     color: c.surface,
          //     shape: BoxShape.circle,
          //     boxShadow: [
          //       BoxShadow(
          //         color: c.primary.withValues(alpha: 0.12),
          //         blurRadius: 24,
          //         offset: const Offset(0, 8),
          //       ),
          //     ],
          //   ),
          //   child: const BrandMark(size: 84),
          // ),
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

// ── Page 2: Reading Preferences ──────────────────────────────────────────────

class _ReadingPreferencesPage extends StatelessWidget {
  const _ReadingPreferencesPage({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = Settings.of(context);
    final isAmharic = s is AmStrings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              s.onboardingPrefsTitle,
              style: AppTypography.amharicHeading.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.textOnParchment,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.onboardingPrefsSubtitle,
              style: AppTypography.amharicCaption.copyWith(
                fontSize: 14,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Preference Controls Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Column(
                children: [
                  // Language Selection
                  Row(
                    children: [
                      Text(
                        s.settingLanguage,
                        style: AppTypography.amharicLabel.copyWith(
                          color: c.textOnParchment,
                        ),
                      ),
                      const Spacer(),
                      _LangOptionChip(
                        label: s.langAmharic,
                        selected: isAmharic,
                        onTap: () =>
                            L10n.switchLanguage(context, AppLanguage.amharic),
                      ),
                      const SizedBox(width: 8),
                      _LangOptionChip(
                        label: s.langEnglish,
                        selected: !isAmharic,
                        onTap: () =>
                            L10n.switchLanguage(context, AppLanguage.english),
                      ),
                    ],
                  ),
                  Divider(color: c.borderSubtle, height: 24),

                  // Geez Numerals Toggle
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.settingGeezNums,
                              style: AppTypography.amharicLabel.copyWith(
                                color: c.textOnParchment,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.settingGeezNumsHint,
                              style: AppTypography.amharicCaption.copyWith(
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.useGeezNumbers,
                        activeThumbColor: c.primary,
                        activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
                        onChanged: (val) {
                          Settings.update(
                            context,
                            settings.copyWith(useGeezNumbers: val),
                          );
                        },
                      ),
                    ],
                  ),
                  Divider(color: c.borderSubtle, height: 24),

                  // Font Size Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.readingSettingsFontSize,
                            style: AppTypography.amharicLabel.copyWith(
                              color: c.textOnParchment,
                            ),
                          ),
                          Text(
                            '${settings.fontSize.toInt()} pt',
                            style: AppTypography.englishCaption.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.fontSize.clamp(14.0, 26.0),
                        min: 14.0,
                        max: 26.0,
                        divisions: 12,
                        activeColor: c.primary,
                        onChanged: (val) {
                          Settings.update(
                            context,
                            settings.copyWith(fontSize: val),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Preview Card
            Text(
              s.readingSettingsPreview,
              style: AppTypography.amharicLabel.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: settings.isDarkReader
                    ? readerDarkBg
                    : AppColors.parchment,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Text(
                s.onboardingPreviewVerseText,
                style: TextStyle(
                  fontFamily: readerFonts[settings.bodyFontIndex],
                  fontSize: settings.fontSize,
                  color: settings.isDarkReader
                      ? readerDarkText
                      : AppColors.textOnParchment,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LangOptionChip extends StatelessWidget {
  const _LangOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: selected ? Colors.white : c.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Page 3: Verse Actions ────────────────────────────────────────────────────

class _VerseActionsPage extends StatelessWidget {
  const _VerseActionsPage({required this.s});
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
          Text(
            s.onboardingActionsTitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicHeading.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textOnParchment,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.onboardingActionsSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.amharicCaption.copyWith(
              fontSize: 14,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 32),

          // Static Illustration Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlighted Verse Sample
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.onboardingSampleVerseNumber,
                        style: AppTypography.amharicLabel.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.onboardingSampleVerseText,
                          style: AppTypography.amharicBody.copyWith(
                            fontSize: 15,
                            color: c.textOnParchment,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Bar Mockup
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.parchment,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionBarItemMock(
                        icon: Icons.border_color_rounded,
                        label: s.verseHighlight,
                        color: c.accentDeep,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.edit_note_rounded,
                        label: s.verseNote,
                        color: c.primary,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.bookmark_rounded,
                        label: s.verseBookmark,
                        color: c.accentDeep,
                      ),
                      _ActionBarItemMock(
                        icon: Icons.share_rounded,
                        label: s.verseShare,
                        color: c.textOnParchment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ActionBarItemMock extends StatelessWidget {
  const _ActionBarItemMock({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Page 4: Optional Sign-In ─────────────────────────────────────────────────

class _OptionalSignInPage extends StatelessWidget {
  const _OptionalSignInPage({
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

          // Icon
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

          // Equally Weighted Buttons (Same visual prominence, same size)
          Row(
            children: [
              // Sign In Button
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
              // Not Now Button (Equally weighted!)
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
