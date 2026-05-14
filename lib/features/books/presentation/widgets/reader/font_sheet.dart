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
                onChanged: (v) => Settings.update(
                  context,
                  settings.copyWith(continuousReading: v),
                ),
                activeThumbColor: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Font size slider
          FontSizeSlider(
            fontSize: settings.fontSize,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            onChanged: (v) =>
                Settings.update(context, settings.copyWith(fontSize: v)),
          ),
          const SizedBox(height: 20),

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
    );
  }
}
