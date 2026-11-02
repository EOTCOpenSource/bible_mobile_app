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

class LineHeightSlider extends StatelessWidget {
  const LineHeightSlider({
    super.key,
    required this.lineHeight,
    required this.accentColor,
    required this.mutedColor,
    required this.textColor,
    required this.onChanged,
  });

  final double lineHeight;
  final Color accentColor;
  final Color mutedColor;
  final Color textColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.format_line_spacing_rounded, size: 18, color: mutedColor),
        Expanded(
          child: Slider(
            value: lineHeight.clamp(1.2, 2.2),
            min: 1.2,
            max: 2.2,
            divisions: 10,
            activeColor: accentColor,
            inactiveColor: mutedColor.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
        Text(
          lineHeight.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MarginScaleSlider extends StatelessWidget {
  const MarginScaleSlider({
    super.key,
    required this.marginScale,
    required this.accentColor,
    required this.mutedColor,
    required this.textColor,
    required this.onChanged,
  });

  final double marginScale;
  final Color accentColor;
  final Color mutedColor;
  final Color textColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.swap_horiz_rounded, size: 20, color: mutedColor),
        Expanded(
          child: Slider(
            value: marginScale.clamp(0.6, 1.6),
            min: 0.6,
            max: 1.6,
            divisions: 10,
            activeColor: accentColor,
            inactiveColor: mutedColor.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
        Text(
          '${(marginScale * 100).round()}%',
          style: TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TextAlignSelector extends StatelessWidget {
  const TextAlignSelector({
    super.key,
    required this.textAlign,
    required this.accentColor,
    required this.mutedColor,
    required this.textColor,
    required this.surfaceColor,
    required this.startLabel,
    required this.justifyLabel,
    required this.onChanged,
  });

  final int textAlign;
  final Color accentColor;
  final Color mutedColor;
  final Color textColor;
  final Color surfaceColor;
  final String startLabel;
  final String justifyLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mutedColor.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _AlignOption(
              label: startLabel,
              icon: Icons.format_align_left_rounded,
              isSelected: textAlign == 0,
              accentColor: accentColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _AlignOption(
              label: justifyLabel,
              icon: Icons.format_align_justify_rounded,
              isSelected: textAlign == 1,
              accentColor: accentColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignOption extends StatelessWidget {
  const _AlignOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected ? Border.all(color: accentColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : mutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.amharicCaption.copyWith(
                color: isSelected ? accentColor : textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepScreenOnToggle extends StatelessWidget {
  const KeepScreenOnToggle({
    super.key,
    required this.keepScreenOn,
    required this.label,
    required this.accentColor,
    required this.textColor,
    required this.onChanged,
  });

  final bool keepScreenOn;
  final String label;
  final Color accentColor;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.screen_lock_portrait_rounded,
          size: 20,
          color: keepScreenOn ? accentColor : textColor.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.amharicLabel.copyWith(color: textColor),
        ),
        const Spacer(),
        Switch(
          value: keepScreenOn,
          onChanged: onChanged,
          activeThumbColor: accentColor,
        ),
      ],
    );
  }
}
