import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book_index_entry.dart';

class ReaderToolbar extends StatelessWidget {
  const ReaderToolbar({
    super.key,
    required this.entry,
    required this.currentChapter,
    required this.useGeez,
    required this.isAmharic,
    required this.bgColor,
    required this.textColor,
    required this.mutedColor,
    required this.s,
    required this.onBack,
    required this.onFontSettings,
  });

  final BookIndexEntry entry;
  final int currentChapter;
  final bool useGeez;
  final bool isAmharic;
  final Color bgColor;
  final Color textColor;
  final Color mutedColor;
  final AppStrings s;
  final VoidCallback onBack;
  final VoidCallback onFontSettings;

  String get _label {
    final n    = currentChapter + 1;
    final ch   = useGeez ? toGeez(n) : '$n';
    final book = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    return '$book · ${s.chapterAbbr} $ch';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Menu / back
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 22, color: mutedColor),
            onPressed: onBack,
          ),
          // Chapter dropdown (center)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _label,
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: mutedColor),
                ],
              ),
            ),
          ),
          // Aa — opens font settings
          GestureDetector(
            onTap: onFontSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
          ),
          // Search
          IconButton(
            icon: Icon(Icons.search_rounded, size: 20, color: mutedColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
