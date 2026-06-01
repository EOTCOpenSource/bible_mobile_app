import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../books/presentation/widgets/reader/constants.dart';
import '../verse_card_models.dart';
import '../verse_card_state.dart';

class TextPicker extends StatelessWidget {
  final VerseCardState state;
  final ValueChanged<VerseCardState> onChanged;

  const TextPicker({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font family selection
          Text(
            s.cardFontLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: readerFonts.length,
              itemBuilder: (context, index) {
                final fontName = readerFontNames[index];
                final isSelected = state.fontIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      fontName,
                      style: TextStyle(
                        fontFamily: readerFonts[index],
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) onChanged(state.copyWith(fontIndex: index));
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Font size selection
          Row(
            children: [
              Text(
                s.cardSizeLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                '${state.fontSize.round()}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          Slider(
            value: state.fontSize,
            min: 14.0,
            max: 32.0,
            divisions: 18,
            label: '${state.fontSize.round()}',
            onChanged: (val) => onChanged(state.copyWith(fontSize: val)),
          ),
          const SizedBox(height: 12),

          // Color & Alignment row
          Row(
            children: [
              // Text Color Mode
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Colour',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: [
                        state.textColorMode == CardTextColorMode.light,
                        state.textColorMode == CardTextColorMode.dark,
                      ],
                      onPressed: (index) {
                        onChanged(state.copyWith(
                          textColorMode: index == 0 ? CardTextColorMode.light : CardTextColorMode.dark,
                        ));
                      },
                      borderRadius: BorderRadius.circular(10),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
                      children: [
                        Text(s.cardColorLight, style: const TextStyle(fontSize: 12)),
                        Text(s.cardColorDark, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Text Alignment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alignment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: [
                        state.textAlign == TextAlign.left,
                        state.textAlign == TextAlign.center,
                        state.textAlign == TextAlign.right,
                      ],
                      onPressed: (index) {
                        onChanged(state.copyWith(
                          textAlign: index == 0
                              ? TextAlign.left
                              : index == 1
                                  ? TextAlign.center
                                  : TextAlign.right,
                        ));
                      },
                      borderRadius: BorderRadius.circular(10),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
                      children: const [
                        Icon(Icons.align_horizontal_left_rounded, size: 18),
                        Icon(Icons.align_horizontal_center_rounded, size: 18),
                        Icon(Icons.align_horizontal_right_rounded, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
