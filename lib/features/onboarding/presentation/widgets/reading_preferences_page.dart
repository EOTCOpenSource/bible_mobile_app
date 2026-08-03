import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/reader/constants.dart';

class ReadingPreferencesPage extends StatelessWidget {
  const ReadingPreferencesPage({super.key, required this.s});

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Column(
                children: [
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
