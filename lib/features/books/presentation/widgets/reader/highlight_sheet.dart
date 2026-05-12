import 'package:flutter/material.dart';
import '../../../../../core/annotations/annotation_models.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class HighlightSheet extends StatelessWidget {
  const HighlightSheet({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    required this.onRemove,
    required this.surfaceColor,
    required this.textColor,
  });

  final Color? currentColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onRemove;
  final Color surfaceColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'ጎላ አድርጎ ማሳየት',
            style: AppTypography.amharicLabel.copyWith(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorCircle(
                color: null,
                isSelected: currentColor == null,
                onTap: onRemove,
                textColor: textColor,
              ),
              for (final color in highlightPalette)
                _ColorCircle(
                  color: color,
                  isSelected: currentColor?.toARGB32() == color.toARGB32(),
                  onTap: () => onColorSelected(color),
                  textColor: textColor,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
  });

  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (color == null
                    ? textColor.withValues(alpha: 0.3)
                    : Colors.transparent),
            width: isSelected ? 3 : 1.5,
          ),
        ),
        child: color == null
            ? Icon(Icons.format_color_reset_rounded,
                size: 22, color: textColor.withValues(alpha: 0.6))
            : isSelected
                ? const Icon(Icons.check_rounded,
                    size: 20, color: Colors.black54)
                : null,
      ),
    );
  }
}
