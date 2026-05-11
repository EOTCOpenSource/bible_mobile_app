import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import 'constants.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
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

class FontSizeSlider extends StatelessWidget {
  const FontSizeSlider({
    super.key,
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

class FontDropdown extends StatelessWidget {
  const FontDropdown({
    super.key,
    required this.selectedIndex,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.onSelect,
  });

  final int selectedIndex;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Ensure the dropdown menu itself has a solid background color
    final effectiveDropdownColor = surfaceColor == Colors.transparent 
        ? Theme.of(context).canvasColor 
        : surfaceColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mutedColor.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: mutedColor),
          dropdownColor: effectiveDropdownColor,
          borderRadius: BorderRadius.circular(14),
          menuMaxHeight: 350,
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
          items: [
            for (int i = 0; i < readerFonts.length; i++)
              DropdownMenuItem(
                value: i,
                child: Row(
                  children: [
                    Text(
                      'መጽሐፍ ቅዱስ',
                      style: TextStyle(
                        fontFamily: readerFonts[i],
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '- ${readerFontNames[i]}',
                      style: TextStyle(
                        fontFamily: AppTypography.nokiaPureheadline,
                        fontSize: 13,
                        color: mutedColor,
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
