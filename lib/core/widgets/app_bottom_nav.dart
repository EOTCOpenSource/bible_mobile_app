import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    (Icons.home_rounded,      Icons.home_outlined),
    (Icons.menu_book_rounded, Icons.menu_book_outlined),
    (Icons.search_rounded,    Icons.search_rounded),
    (Icons.bookmark_rounded,  Icons.bookmark_border_rounded),
    (Icons.person_rounded,    Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final labels = [s.navHome, s.navBooks, s.navSearch, s.navSaved, s.navMe];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
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
                  splashColor: AppColors.primary.withValues(alpha: 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isActive ? activeIcon : inactiveIcon,
                          key: ValueKey(isActive),
                          size: 24,
                          color: isActive ? AppColors.primary : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: AppTypography.amharicCaption.copyWith(
                          fontSize: 10,
                          color: isActive ? AppColors.primary : AppColors.textCaption,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
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
