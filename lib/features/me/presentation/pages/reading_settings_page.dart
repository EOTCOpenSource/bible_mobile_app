import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/edition_switcher.dart';
import '../../../books/presentation/widgets/reader/constants.dart';
import '../../../books/presentation/widgets/reader/font_settings_widgets.dart';
import '../../../books/providers/edition_providers.dart';

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
                lineHeight: 1.6,
                marginScale: 1.0,
                textAlign: 0,
                keepScreenOn: false,
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
            lineHeight: settings.lineHeight,
            marginScale: settings.marginScale,
            textAlign: settings.textAlign,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            surfaceColor: surfaceColor,
            previewLabel: s.readingSettingsPreview,
          ),
          const SizedBox(height: 24),

          // ── Parallel translation ──────────────────────────────────────────
          _ParallelRow(
            label: s.parallelSettingLabel,
            offLabel: s.parallelOff,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            sheetTheme: EditionSheetTheme(
              surface: surfaceColor,
              text: textColor,
              muted: mutedColor,
              accent: accentColor,
              border: mutedColor.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 20),

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
          const SizedBox(height: 12),

          // ── Keep screen on toggle ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: KeepScreenOnToggle(
              keepScreenOn: settings.keepScreenOn,
              label: s.readingSettingsKeepScreenOn,
              accentColor: accentColor,
              textColor: textColor,
              onChanged: (v) => Settings.update(
                context,
                settings.copyWith(keepScreenOn: v),
              ),
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

          // ── Line height slider ───────────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsLineHeight,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),
          LineHeightSlider(
            lineHeight: settings.lineHeight,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            onChanged: (v) => Settings.update(
              context,
              settings.copyWith(lineHeight: v),
            ),
          ),
          const SizedBox(height: 24),

          // ── Margin scale slider ──────────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsMarginScale,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),
          MarginScaleSlider(
            marginScale: settings.marginScale,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            onChanged: (v) => Settings.update(
              context,
              settings.copyWith(marginScale: v),
            ),
          ),
          const SizedBox(height: 24),

          // ── Text alignment selector ──────────────────────────────────────
          SectionLabel(
            label: s.readingSettingsTextAlign,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 10),
          TextAlignSelector(
            textAlign: settings.textAlign,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            surfaceColor: surfaceColor,
            startLabel: s.readingSettingsAlignStart,
            justifyLabel: s.readingSettingsAlignJustify,
            onChanged: (v) => Settings.update(
              context,
              settings.copyWith(textAlign: v),
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
    required this.lineHeight,
    required this.marginScale,
    required this.textAlign,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.previewLabel,
  });

  final String bodyFont;
  final String titleFont;
  final double fontSize;
  final double lineHeight;
  final double marginScale;
  final int textAlign;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final Color surfaceColor;
  final String previewLabel;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = (20.0 * marginScale).clamp(10.0, 40.0);
    final effectiveAlign = textAlign == 1 ? TextAlign.justify : TextAlign.start;

    return Container(
      padding: EdgeInsets.all(effectivePadding),
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
            textAlign: effectiveAlign,
            text: TextSpan(
              style: TextStyle(
                fontFamily: bodyFont,
                fontSize: fontSize,
                color: textColor,
                height: lineHeight,
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

/// Opens the edition chooser at its parallel-column controls.
///
/// A row rather than a switch: choosing *which* edition sits alongside is the
/// decision, and there is no sensible default second translation to toggle on.
class _ParallelRow extends ConsumerWidget {
  const _ParallelRow({
    required this.label,
    required this.offLabel,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.sheetTheme,
  });

  final String label;
  final String offLabel;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final EditionSheetTheme sheetTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parallel = ref.watch(secondaryEditionTitleProvider).valueOrNull;

    return InkWell(
      onTap: () => showEditionSwitcher(context, theme: sheetTheme),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.view_column_outlined, size: 17, color: mutedColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.amharicLabel.copyWith(color: textColor),
              ),
            ),
            Text(
              parallel ?? offLabel,
              style: AppTypography.amharicCaption.copyWith(
                color: parallel == null ? mutedColor : accentColor,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 18, color: mutedColor),
          ],
        ),
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
