import 'package:flutter/material.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/settings/app_settings.dart';
import 'constants.dart';
import 'font_settings_widgets.dart';

/// Compact bottom-sheet for quick font/size tweaks.
/// Uses global [AppSettings] — same data the full ReadingSettingsPage modifies.
class ReaderFontSheet extends StatelessWidget {
  const ReaderFontSheet({
    super.key,
    required this.settings,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onSizeChange,
    required this.onFontChange,
  });

  final AppSettings settings;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<double> onSizeChange;
  final ValueChanged<int> onFontChange;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final isDark = settings.isDarkReader;
    
    // Use a solid color for dropdowns to prevent "black backdrop" glitches
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

          // Font size slider
          FontSizeSlider(
            fontSize: settings.fontSize,
            accentColor: accentColor,
            mutedColor: mutedColor,
            textColor: textColor,
            onChanged: onSizeChange,
          ),
          const SizedBox(height: 20),

          // Body Font Dropdown
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
            onSelect: onFontChange,
          ),
          const SizedBox(height: 16),

          // Title Font Dropdown
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
