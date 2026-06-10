import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../verse_card_models.dart';
import '../verse_card_state.dart';

class RatioPicker extends StatelessWidget {
  final VerseCardState state;
  final ValueChanged<VerseCardState> onChanged;

  const RatioPicker({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: CardAspectRatio.values.map((aspectRatio) {
              final isSelected = state.aspectRatio == aspectRatio;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => onChanged(state.copyWith(aspectRatio: aspectRatio)),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconForRatio(aspectRatio),
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aspectRatio.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getRatioLabel(aspectRatio, s),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRatio(CardAspectRatio ratio) {
    switch (ratio) {
      case CardAspectRatio.square:
        return Icons.crop_square_rounded;
      case CardAspectRatio.portrait:
        return Icons.crop_portrait_rounded;
      case CardAspectRatio.story:
        return Icons.crop_16_9_rounded; // Represents a long vertical ratio
    }
  }

  String _getRatioLabel(CardAspectRatio ratio, dynamic s) {
    switch (ratio) {
      case CardAspectRatio.square:
        return s.cardRatioSquare;
      case CardAspectRatio.portrait:
        return s.cardRatioPortrait;
      case CardAspectRatio.story:
        return s.cardRatioStory;
    }
  }
}
