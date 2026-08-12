import 'package:flutter/material.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/theme/app_typography.dart';
import 'constants.dart';
import 'font_settings_widgets.dart';

/// Compact bottom-sheet for quick font/size/layout tweaks.
/// Reads [Settings] live so all controls stay in sync while the sheet is open.
class ReaderFontSheet extends StatelessWidget {
  const ReaderFontSheet({
    super.key,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
  });

  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final s        = L10n.of(context);
    final settings = Settings.of(context);          // live — rebuilds on change
    final isDark   = settings.isDarkReader;
    final dropdownSurface = isDark ? readerDarkSurface : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Layout mode toggle
            Row(
              children: [
                Text(
                  s.readingSettingsContinuous,
                  style: AppTypography.amharicLabel.copyWith(color: textColor),
                ),
                const Spacer(),
                Switch(
                  value: settings.continuousReading,
                  // The two are mutually exclusive: continuous reading runs a
                  // whole section together as one paragraph, which leaves the
                  // apparatus nowhere to sit — it belongs under the verse it
                  // annotates, and there are no separate verses to sit under.
                  // Turning either on turns the other off rather than leaving a
                  // switch on that quietly does nothing.
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(
                      continuousReading: v,
                      showCrossRefMarkers:
                          v ? false : settings.showCrossRefMarkers,
                    ),
                  ),
                  activeThumbColor: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Keep screen on toggle
            KeepScreenOnToggle(
              keepScreenOn: settings.keepScreenOn,
              label: s.readingSettingsKeepScreenOn,
              accentColor: accentColor,
              textColor: textColor,
              onChanged: (v) => Settings.update(
                context,
                settings.copyWith(keepScreenOn: v),
              ),
            ),
            const SizedBox(height: 12),

            // Show cross-reference markers toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.readingSettingsShowCrossRefMarkers,
                        style: AppTypography.amharicLabel.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.readingSettingsShowCrossRefMarkersHint,
                        style: AppTypography.amharicCaption.copyWith(color: mutedColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.showCrossRefMarkers,
                  // See the continuous-reading switch above: one excludes the
                  // other, in both directions.
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(
                      showCrossRefMarkers: v,
                      continuousReading: v ? false : settings.continuousReading,
                    ),
                  ),
                  activeThumbColor: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font size slider
            SectionLabel(
              label: s.readingSettingsFontSize,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 4),
            FontSizeSlider(
              fontSize: settings.fontSize,
              accentColor: accentColor,
              mutedColor: mutedColor,
              textColor: textColor,
              onChanged: (v) =>
                  Settings.update(context, settings.copyWith(fontSize: v)),
            ),
            const SizedBox(height: 16),

            // Line height slider
            SectionLabel(
              label: s.readingSettingsLineHeight,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 4),
            LineHeightSlider(
              lineHeight: settings.lineHeight,
              accentColor: accentColor,
              mutedColor: mutedColor,
              textColor: textColor,
              onChanged: (v) =>
                  Settings.update(context, settings.copyWith(lineHeight: v)),
            ),
            const SizedBox(height: 16),

            // Margin scale slider
            SectionLabel(
              label: s.readingSettingsMarginScale,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 4),
            MarginScaleSlider(
              marginScale: settings.marginScale,
              accentColor: accentColor,
              mutedColor: mutedColor,
              textColor: textColor,
              onChanged: (v) =>
                  Settings.update(context, settings.copyWith(marginScale: v)),
            ),
            const SizedBox(height: 16),

            // Text alignment selector
            SectionLabel(
              label: s.readingSettingsTextAlign,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 8),
            TextAlignSelector(
              textAlign: settings.textAlign,
              accentColor: accentColor,
              mutedColor: mutedColor,
              textColor: textColor,
              surfaceColor: dropdownSurface,
              startLabel: s.readingSettingsAlignStart,
              justifyLabel: s.readingSettingsAlignJustify,
              onChanged: (v) =>
                  Settings.update(context, settings.copyWith(textAlign: v)),
            ),
            const SizedBox(height: 16),

            // Body font dropdown
            SectionLabel(
              label: s.readingSettingsBodyFont,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 8),
            FontDropdown(
              selectedIndex: settings.bodyFontIndex,
              accentColor: accentColor,
              textColor: textColor,
              mutedColor: mutedColor,
              surfaceColor: dropdownSurface,
              onSelect: (i) =>
                  Settings.update(context, settings.copyWith(bodyFontIndex: i)),
            ),
            const SizedBox(height: 16),

            // Title font dropdown
            SectionLabel(
              label: s.readingSettingsTitleFont,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 8),
            FontDropdown(
              selectedIndex: settings.titleFontIndex,
              accentColor: accentColor,
              textColor: textColor,
              mutedColor: mutedColor,
              surfaceColor: dropdownSurface,
              onSelect: (i) =>
                  Settings.update(context, settings.copyWith(titleFontIndex: i)),
            ),
          ],
        ),
      ),
    );
  }
}
