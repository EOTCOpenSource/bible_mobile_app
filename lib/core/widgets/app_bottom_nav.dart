import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../settings/app_settings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.matchReaderShellColors = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// When true (reader route is open), bar matches reader parchment / night.
  /// Otherwise uses [BuildContext] theme colors like the rest of the app.
  final bool matchReaderShellColors;

  static const _icons = [
    (Icons.home_rounded, Icons.home_outlined),
    (Icons.menu_book_rounded, Icons.menu_book_outlined),
    (Icons.search_rounded, Icons.search_rounded),
    (Icons.bookmark_rounded, Icons.bookmark_border_rounded),
    (Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final labels = [s.navHome, s.navBooks, s.navSearch, s.navSaved, s.navMe];
    final c = context.colors;

    final Color barBg;
    final Color borderColor;
    final Color activeColor;
    final Color inactiveColor;
    final List<BoxShadow> shadows;
    final Color splashColor;

    if (matchReaderShellColors) {
      final readerNight = Settings.of(context).isDarkReader;
      if (readerNight) {
        barBg = AppColors.readerShellDarkBg;
        borderColor = AppColors.readerShellDarkMuted.withValues(alpha: 0.35);
        activeColor = AppColors.readerShellDarkAccent;
        inactiveColor = AppColors.readerShellDarkMuted;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ];
        splashColor = activeColor.withValues(alpha: 0.12);
      } else {
        barBg = AppColors.parchment;
        borderColor = AppColors.borderSubtle;
        activeColor = AppColors.accentDeep;
        inactiveColor = AppColors.textCaption;
        shadows = const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4)),
        ];
        splashColor = activeColor.withValues(alpha: 0.12);
      }
    } else {
      barBg = c.surface;
      borderColor = c.borderSubtle;
      activeColor = c.primary;
      inactiveColor = c.textCaption;
      shadows = const [
        BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
      ];
      splashColor = c.primary.withValues(alpha: 0.06);
    }

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: shadows,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_icons.length, (i) {
              final (activeIcon, inactiveIcon) = _icons[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  highlightColor: Colors.transparent,
                  splashColor: splashColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isActive ? activeIcon : inactiveIcon,
                          key: ValueKey(isActive),
                          size: 24,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: AppTypography.amharicCaption.copyWith(
                          fontSize: 10,
                          color: isActive ? activeColor : inactiveColor,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
