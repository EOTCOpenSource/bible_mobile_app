import 'package:flutter/material.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'constants.dart';

/// Compact bottom-sheet for quick font/size/dark tweaks.
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
    required this.onDarkToggle,
    required this.onOpenFullSettings,
  });

  final AppSettings settings;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<double> onSizeChange;
  final ValueChanged<int> onFontChange;
  final VoidCallback onDarkToggle;
  final VoidCallback onOpenFullSettings;

  @override
  Widget build(BuildContext context) {
    final fontSize = settings.fontSize;
    final fontIdx  = settings.bodyFontIndex;
    final isDark   = settings.isDarkReader;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Font size row
          Row(
            children: [
              GestureDetector(
                onTap: () => onSizeChange((fontSize - 2).clamp(13, 26)),
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
                  onChanged: onSizeChange,
                ),
              ),
              GestureDetector(
                onTap: () => onSizeChange((fontSize + 2).clamp(13, 26)),
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
          ),
          const SizedBox(height: 10),
          // Font family picker (horizontal scroll — all 9 fonts)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < readerFonts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onFontChange(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: i == fontIdx
                              ? accentColor.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == fontIdx
                                ? accentColor
                                : mutedColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          readerFontNames[i],
                          style: TextStyle(
                            fontFamily: readerFonts[i],
                            fontSize: 14,
                            color: i == fontIdx ? accentColor : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Night mode toggle
          Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: mutedColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isDark ? 'Light Mode' : 'Night Mode',
                  style: TextStyle(
                    fontFamily: AppTypography.nokiaPureheadline,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) => onDarkToggle(),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // "More settings" link
          GestureDetector(
            onTap: onOpenFullSettings,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'All Reading Settings',
                    style: TextStyle(
                      fontFamily: AppTypography.nokiaPureheadline,
                      fontSize: 12,
                      color: accentColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
