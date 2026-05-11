import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/reader/constants.dart';

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
                isDarkReader: false,
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

          // ── Font size slider ──────────────────────────────────────────────
          _SectionLabel(
            label: s.readingSettingsFontSize,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),
          _FontSizeSlider(
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
          _SectionLabel(
            label: s.readingSettingsBodyFont,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          _FontGrid(
            selectedIndex: settings.bodyFontIndex,
            accentColor: accentColor,
            mutedColor: mutedColor,
            surfaceColor: surfaceColor,
            onSelect: (i) => Settings.update(
              context,
              settings.copyWith(bodyFontIndex: i),
            ),
          ),
          const SizedBox(height: 24),

          // ── Title font picker ─────────────────────────────────────────────
          _SectionLabel(
            label: s.readingSettingsTitleFont,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          _FontGrid(
            selectedIndex: settings.titleFontIndex,
            accentColor: accentColor,
            mutedColor: mutedColor,
            surfaceColor: surfaceColor,
            onSelect: (i) => Settings.update(
              context,
              settings.copyWith(titleFontIndex: i),
            ),
          ),
          const SizedBox(height: 24),

          // ── Night mode toggle ─────────────────────────────────────────────
          _NightModeRow(
            isDark: isDark,
            textColor: textColor,
            mutedColor: mutedColor,
            label: s.readingSettingsNightMode,
            onToggle: () => Settings.update(
              context,
              settings.copyWith(isDarkReader: !isDark),
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

// ── Section label ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.textColor,
    required this.mutedColor,
  });

  final String label;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppTypography.amharicLabel.copyWith(color: textColor),
      ),
    );
  }
}

// ── Font size slider ────────────────────────────────────────────────────────────

class _FontSizeSlider extends StatelessWidget {
  const _FontSizeSlider({
    required this.fontSize,
    required this.accentColor,
    required this.mutedColor,
    required this.textColor,
    required this.onChanged,
  });

  final double fontSize;
  final Color accentColor;
  final Color mutedColor;
  final Color textColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged((fontSize - 2).clamp(13, 26)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'A',
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: 13,
                color: mutedColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: fontSize,
            min: 13,
            max: 26,
            divisions: 6,
            activeColor: accentColor,
            inactiveColor: mutedColor.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
        GestureDetector(
          onTap: () => onChanged((fontSize + 2).clamp(13, 26)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'A',
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: 20,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Font grid ───────────────────────────────────────────────────────────────────

class _FontGrid extends StatelessWidget {
  const _FontGrid({
    required this.selectedIndex,
    required this.accentColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.onSelect,
  });

  final int selectedIndex;
  final Color accentColor;
  final Color mutedColor;
  final Color surfaceColor;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < readerFonts.length; i++)
          GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: i == selectedIndex
                    ? accentColor.withValues(alpha: 0.14)
                    : surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: i == selectedIndex
                      ? accentColor
                      : mutedColor.withValues(alpha: 0.25),
                  width: i == selectedIndex ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'አ',
                    style: TextStyle(
                      fontFamily: readerFonts[i],
                      fontSize: 22,
                      color: i == selectedIndex ? accentColor : mutedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    readerFontNames[i],
                    style: TextStyle(
                      fontFamily: readerFonts[i],
                      fontSize: 10,
                      color: i == selectedIndex
                          ? accentColor
                          : mutedColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Night mode row ──────────────────────────────────────────────────────────────

class _NightModeRow extends StatelessWidget {
  const _NightModeRow({
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.label,
    required this.onToggle,
  });

  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: mutedColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.amharicLabel.copyWith(color: textColor),
          ),
        ),
        Switch(
          value: isDark,
          onChanged: (_) => onToggle(),
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}
