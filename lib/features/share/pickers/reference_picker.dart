import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../verse_card_state.dart';

class ReferencePicker extends StatelessWidget {
  final VerseCardState state;
  final ValueChanged<VerseCardState> onChanged;

  const ReferencePicker({
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
        children: [
          // Show/Hide reference switch
          Row(
            children: [
              Text(
                s.cardRefShow,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70  : Colors.black.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              Switch(
                value: state.showReference,
                onChanged: (val) => onChanged(state.copyWith(showReference: val)),
              ),
            ],
          ),
          const Divider(),

          // Conditional options if reference is shown
          Opacity(
            opacity: state.showReference ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !state.showReference,
              child: Column(
                children: [
                  // Numeral style
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.cardRefNumeralStyle,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.cardRefNumeralHint,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ToggleButtons(
                        isSelected: [state.useGeezRef, !state.useGeezRef],
                        onPressed: (index) {
                          onChanged(state.copyWith(useGeezRef: index == 0));
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
                        children: [
                          Text(s.cardRefGeez, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                          Text(s.cardRefArabic, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Language
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.cardRefBookLang,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.cardRefBookLangHint,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ToggleButtons(
                        isSelected: [state.useAmharicBookName, !state.useAmharicBookName],
                        onPressed: (index) {
                          onChanged(state.copyWith(useAmharicBookName: index == 0));
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 70),
                        children: [
                          Text(s.cardRefAmharic, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                          Text(s.cardRefEnglish, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ],
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
