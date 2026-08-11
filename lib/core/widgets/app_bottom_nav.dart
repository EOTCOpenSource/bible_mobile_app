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

  /// Search is deliberately absent: it belongs to a book, not to the whole
  /// app, so it lives on the books tab and in the reader toolbar where a scope
  /// already exists. The middle slot goes to reading plans instead.
  static const _icons = [
    (Icons.home_rounded, Icons.home_outlined),
    (Icons.menu_book_rounded, Icons.menu_book_outlined),
    (Icons.event_note_rounded, Icons.event_note_outlined),
    (Icons.bookmark_rounded, Icons.bookmark_border_rounded),
    (Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final labels = [s.navHome, s.navBooks, s.navPlans, s.navSaved, s.navMe];
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: List.generate(_icons.length, (i) {
                final (activeIcon, inactiveIcon) = _icons[i];
                final isActive = i == selectedIndex;
                final tabAnnouncement =
                    s.semanticsTabAnnouncement(labels[i], i + 1, _icons.length);
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isActive,
                    label: tabAnnouncement,
                    child: InkWell(
                      onTap: () => onTap(i),
                      highlightColor: Colors.transparent,
                      splashColor: splashColor,
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.amharicCaption.copyWith(
                                  fontSize: 10,
                                  color: isActive ? activeColor : inactiveColor,
                                  fontWeight:
                                      isActive ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
