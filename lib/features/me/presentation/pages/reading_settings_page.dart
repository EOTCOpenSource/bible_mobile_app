import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/reader/constants.dart';
import '../../../books/presentation/widgets/reader/font_settings_widgets.dart';

/// Full-page reading customizer — opened from Me settings or the reader Aa sheet.
class ReadingSettingsPage extends StatelessWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s        = L10n.of(context);
    final settings = Settings.of(context);
    final bodyFont  = readerFonts[settings.bodyFontIndex];
    final titleFont = readerFonts[settings.titleFontIndex];
    final isDark    = settings.isDarkReader;

    final bgColor      = isDark ? readerDarkBg      : AppColors.parchment;
    final surfaceColor = isDark ? readerDarkSurface  : Colors.white;
    final textColor    = isDark ? readerDarkText     : AppColors.textOnParchment;
    final mutedColor   = isDark ? readerDarkMuted    : AppColors.textMuted;
    final accentColor  = isDark ? readerDarkAccent   : AppColors.accentDeep;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.readingSettingsTitle,
          style: AppTypography.amharicSubheading.copyWith(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Settings.update(
              context,
              settings.copyWith(
                bodyFontIndex: 0,
                titleFontIndex: 0,
                fontSize: 17.0,
              ),
            ),
            child: Text(
              s.readingSettingsReset,
              style: AppTypography.amharicCaption.copyWith(color: accentColor),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Preview card ──────────────────────────────────────────────────
          _PreviewCard(
            bodyFont: bodyFont,
            titleFont: titleFont,
            fontSize: settings.fontSize,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            surfaceColor: surfaceColor,
            previewLabel: s.readingSettingsPreview,
          ),
          const SizedBox(height: 24),

          // ── Continuous reading toggle ─────────────────────────────────────
          _SettingRow(
            label: s.readingSettingsContinuous,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            value: settings.continuousReading,
            onChanged: (v) => Settings.update(
              context,
              settings.copyWith(continuousReading: v),
            ),
          ),
          const SizedBox(height: 24),

          // ── Font size slider ──────────────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsFontSize,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),
          FontSizeSlider(
            fontSize: settings.fontSize,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            onChanged: (v) => Settings.update(
              context,
              settings.copyWith(fontSize: v),
            ),
          ),
          const SizedBox(height: 24),

          // ── Body font picker ──────────────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsBodyFont,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          FontDropdown(
            selectedIndex: settings.bodyFontIndex,
            accentColor: accentColor,
            textColor: textColor,
            mutedColor: mutedColor,
            surfaceColor: surfaceColor,
            onSelect: (i) => Settings.update(
              context,
              settings.copyWith(bodyFontIndex: i),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title font picker ─────────────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsTitleFont,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          FontDropdown(
            selectedIndex: settings.titleFontIndex,
            accentColor: accentColor,
            textColor: textColor,
            mutedColor: mutedColor,
            surfaceColor: surfaceColor,
            onSelect: (i) => Settings.update(
              context,
              settings.copyWith(titleFontIndex: i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview card ────────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.bodyFont,
    required this.titleFont,
    required this.fontSize,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.previewLabel,
  });

  final String bodyFont;
  final String titleFont;
  final double fontSize;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final Color surfaceColor;
  final String previewLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mutedColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 14, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                previewLabel,
                style: AppTypography.englishLabel.copyWith(
                  color: mutedColor,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'መዝሙረ ዳዊት ፩',
            style: TextStyle(
              fontFamily: titleFont,
              fontSize: fontSize + 4,
              fontWeight: FontWeight.w700,
              color: accentColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: bodyFont,
                fontSize: fontSize,
                color: textColor,
                height: 2.0,
              ),
              children: [
                TextSpan(
                  text: '፩ ',
                  style: AppTypography.verseNumber.copyWith(color: accentColor),
                ),
                const TextSpan(
                  text: 'ብፁዕ ውእቱ ብእሲ ዘኢሖረ በምክረ ረሲዓን ወዘኢቆመ ውስተ ፍኖተ ኃጥኣን ወዘኢነበረ ውስተ መንበረ መስተሣልቃን ',
                ),
                TextSpan(
                  text: '፪ ',
                  style: AppTypography.verseNumber.copyWith(color: accentColor),
                ),
                const TextSpan(
                  text: 'ዘእንበለ ሕጉ ለእግዚአብሔር ፈቃዱ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            style: AppTypography.amharicLabel.copyWith(color: textColor),
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: accentColor,
        ),
      ],
    );
  }
}
