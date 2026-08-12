import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/home_widget/home_widget_data.dart';
import '../../../../core/home_widget/home_widget_refresher.dart';
import '../../../../core/home_widget/home_widget_service.dart';
import '../../../../core/home_widget/widget_appearance.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/home_widget_preview.dart';

/// Customises all three Android home screen widgets.
///
/// One page for the three rather than one page each: they share every control
/// but their two toggles, and the thing a user actually wants to compare —
/// "does the maroon look right on my wallpaper?" — is answered by flipping
/// between widgets without leaving the screen. Hence the strip along the top
/// rather than a settings row per widget.
///
/// The preview under it is drawn from the real payload, so the verse in it is
/// today's verse and the streak is the streak actually standing. See
/// [HomeWidgetPreview].
class WidgetsSettingsPage extends ConsumerStatefulWidget {
  const WidgetsSettingsPage({super.key});

  @override
  ConsumerState<WidgetsSettingsPage> createState() =>
      _WidgetsSettingsPageState();
}

class _WidgetsSettingsPageState extends ConsumerState<WidgetsSettingsPage> {
  HomeWidgetKind _selected = HomeWidgetKind.dailyVerse;
  HomeWidgetAppearance _appearance = const HomeWidgetAppearance();
  HomeWidgetData? _data;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final s = L10n.of(context);
    final isAmharic = s is AmStrings;
    final settings = Settings.of(context);

    final appearance = await HomeWidgetService.loadAppearance();
    final data = await previewHomeWidgetData(
      ref,
      s: s,
      isAmharic: isAmharic,
      settings: settings,
    );
    if (!mounted) return;
    setState(() {
      _appearance = appearance;
      _data = data;
    });
  }

  WidgetStyle get _style => _appearance.styleFor(_selected);

  /// Applies a style change to the selected widget.
  ///
  /// [push] is false while a slider is being dragged: writing preferences and
  /// waking three widget providers on every frame of a drag makes the drag
  /// stutter, so the home screen is updated once, when the finger lifts.
  void _setStyle(WidgetStyle style, {bool push = true}) {
    final next = _appearance.withStyle(_selected, style);
    setState(() => _appearance = next);
    if (push) HomeWidgetService.pushAppearance(next);
  }

  /// Changes the streak emoji, which lives in [AppSettings] rather than in the
  /// widget style because the home header and the streak page draw it too.
  ///
  /// Content, not style — so it goes out through the ordinary payload push,
  /// and the preview is rebuilt from that same payload rather than from the
  /// value that was just picked.
  Future<void> _setStreakEmoji(String emoji) async {
    final settings = Settings.of(context);
    if (settings.streakEmoji == emoji) return;

    final updated = settings.copyWith(streakEmoji: emoji);
    Settings.update(context, updated);

    final s = L10n.of(context);
    final data = await previewHomeWidgetData(
      ref,
      s: s,
      isAmharic: s is AmStrings,
      settings: updated,
    );
    if (data == null) return;
    await HomeWidgetService.push(data);
    if (!mounted) return;
    setState(() => _data = data);
  }

  Future<void> _addToHomeScreen() async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pinned = await HomeWidgetService.requestPin(_selected);
    if (!pinned) {
      messenger.showSnackBar(SnackBar(content: Text(s.widgetAddUnsupported)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isDark = settings.isDarkReader;

    final bgColor = isDark ? AppColors.readerShellDarkBg : AppColors.parchment;
    final surfaceColor =
        isDark ? AppColors.readerShellDarkSurface : Colors.white;
    final textColor =
        isDark ? AppColors.readerShellDarkText : AppColors.textOnParchment;
    final mutedColor =
        isDark ? AppColors.readerShellDarkMuted : AppColors.textMuted;
    final accentColor =
        isDark ? AppColors.readerShellDarkAccent : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.widgetsTitle,
          style: AppTypography.amharicSubheading.copyWith(color: textColor),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 40),
        children: [
          if (!HomeWidgetService.isSupported)
            _Note(
              icon: Icons.phone_android_rounded,
              text: s.widgetsAndroidOnly,
              color: mutedColor,
            ),

          // ── Which widget ────────────────────────────────────────────────
          _SectionLabel(text: s.widgetsChooseLabel, color: mutedColor),
          _WidgetChooser(
            selected: _selected,
            s: s,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            onPick: (kind) => setState(() => _selected = kind),
          ),
          const SizedBox(height: 22),

          // ── Preview ─────────────────────────────────────────────────────
          _PreviewStage(
            child: HomeWidgetPreview(
              kind: _selected,
              style: _style,
              data: _data,
              s: s,
              systemDark: isDark,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AddToHomeButton(
              label: s.widgetAddToHome,
              accentColor: accentColor,
              onTap: _addToHomeScreen,
            ),
          ),
          const SizedBox(height: 26),

          // ── Theme ───────────────────────────────────────────────────────
          _SectionLabel(text: s.widgetSectionTheme, color: mutedColor),
          _ThemePicker(
            selected: _style.theme,
            s: s,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
            accentColor: accentColor,
            onPick: (theme) => _setStyle(_style.copyWith(theme: theme)),
          ),
          const SizedBox(height: 22),

          // ── Text size ───────────────────────────────────────────────────
          _SectionLabel(text: s.widgetSectionTextSize, color: mutedColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Segmented<WidgetTextScale>(
              values: WidgetTextScale.values,
              selected: _style.textScale,
              labelOf: (v) => switch (v) {
                WidgetTextScale.small => s.widgetTextSmall,
                WidgetTextScale.medium => s.widgetTextMedium,
                WidgetTextScale.large => s.widgetTextLarge,
              },
              surfaceColor: surfaceColor,
              textColor: textColor,
              mutedColor: mutedColor,
              accentColor: accentColor,
              onPick: (v) => _setStyle(_style.copyWith(textScale: v)),
            ),
          ),
          const SizedBox(height: 22),

          // ── Opacity ─────────────────────────────────────────────────────
          _SectionLabel(text: s.widgetSectionOpacity, color: mutedColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _OpacitySlider(
              value: _style.opacity,
              surfaceColor: surfaceColor,
              textColor: textColor,
              accentColor: accentColor,
              onChanged: (v) =>
                  _setStyle(_style.copyWith(opacity: v), push: false),
              onSettled: (v) => _setStyle(_style.copyWith(opacity: v)),
            ),
          ),
          const SizedBox(height: 22),

          // ── Visible parts ───────────────────────────────────────────────
          _SectionLabel(text: s.widgetSectionOptions, color: mutedColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _ToggleTile(
                    label: _labelToggleName(s),
                    value: _style.showLabel,
                    textColor: textColor,
                    accentColor: accentColor,
                    onChanged: (v) => _setStyle(_style.copyWith(showLabel: v)),
                  ),
                  Divider(height: 1, color: mutedColor.withValues(alpha: 0.15)),
                  _ToggleTile(
                    label: _detailToggleName(s),
                    value: _style.showDetail,
                    textColor: textColor,
                    accentColor: accentColor,
                    onChanged: (v) => _setStyle(_style.copyWith(showDetail: v)),
                  ),
                ],
              ),
            ),
          ),

          // ── Streak emoji ────────────────────────────────────────────────
          if (_selected == HomeWidgetKind.streak) ...[
            const SizedBox(height: 22),
            _SectionLabel(
              text: s.streakEmojiSectionChoose,
              color: mutedColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmojiGrid(
                selected: settings.streakEmoji,
                surfaceColor: surfaceColor,
                accentColor: accentColor,
                onPick: _setStreakEmoji,
              ),
            ),
            const SizedBox(height: 10),
            _Note(
              icon: Icons.info_outline_rounded,
              text: s.streakEmojiWidgetNote,
              color: mutedColor,
            ),
          ],

          const SizedBox(height: 20),
          _Note(
            icon: Icons.open_with_rounded,
            text: s.widgetResizeHint,
            color: mutedColor,
          ),
        ],
      ),
    );
  }

  /// The two toggles mean something different on each widget, so they are
  /// named after what they actually hide rather than after the field.
  String _labelToggleName(AppStrings s) => switch (_selected) {
        HomeWidgetKind.dailyVerse => s.widgetToggleVerseTag,
        HomeWidgetKind.continueReading => s.widgetToggleContinueLabel,
        HomeWidgetKind.streak => s.widgetToggleStreakDays,
      };

  String _detailToggleName(AppStrings s) => switch (_selected) {
        HomeWidgetKind.dailyVerse => s.widgetToggleVerseRef,
        HomeWidgetKind.continueReading => s.widgetToggleProgressBar,
        HomeWidgetKind.streak => s.widgetToggleStreakEmoji,
      };
}

// ── Widget chooser ──────────────────────────────────────────────────────────

/// The horizontal strip of widgets to customise.
///
/// Scrolls rather than wrapping: a row of three cards that never reflows keeps
/// the selected card in the same place on every screen width, and there is
/// room for a fourth widget later without the layout changing shape.
class _WidgetChooser extends StatelessWidget {
  const _WidgetChooser({
    required this.selected,
    required this.s,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onPick,
  });

  final HomeWidgetKind selected;
  final AppStrings s;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<HomeWidgetKind> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: HomeWidgetKind.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final kind = HomeWidgetKind.values[i];
          final isSelected = kind == selected;
          final (icon, label) = switch (kind) {
            HomeWidgetKind.dailyVerse => (
                Icons.auto_stories_rounded,
                s.widgetNameDailyVerse,
              ),
            HomeWidgetKind.continueReading => (
                Icons.play_circle_outline_rounded,
                s.widgetNameContinue,
              ),
            HomeWidgetKind.streak => (
                Icons.local_fire_department_rounded,
                s.widgetNameStreak,
              ),
          };

          return GestureDetector(
            onTap: () => onPick(kind),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.10)
                    : surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : mutedColor.withValues(alpha: 0.18),
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? accentColor : mutedColor,
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicCaption.copyWith(
                      color: isSelected ? accentColor : textColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Preview stage ───────────────────────────────────────────────────────────

/// The backdrop the preview sits on.
///
/// A wallpaper stand-in rather than the page background, because background
/// opacity is the one setting that is invisible against a flat surface — a
/// half-transparent card on a plain page just looks like a lighter card.
class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A3B32),
              Color(0xFF6E5A4A),
              Color(0xFF2E2622),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AddToHomeButton extends StatelessWidget {
  const _AddToHomeButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.add_to_home_screen_rounded, size: 18,
            color: accentColor),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        label: Text(
          label,
          style: AppTypography.amharicLabel.copyWith(
            color: accentColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Controls ────────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({
    required this.selected,
    required this.s,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onPick,
  });

  final WidgetTheme selected;
  final AppStrings s;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<WidgetTheme> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: WidgetTheme.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final theme = WidgetTheme.values[i];
          final isSelected = theme == selected;
          final (swatch, label) = switch (theme) {
            WidgetTheme.auto => (
                const [Color(0xFFFFFFFF), Color(0xFF1E1A16)],
                s.widgetThemeAuto,
              ),
            WidgetTheme.light => (
                const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                s.widgetThemeLight,
              ),
            WidgetTheme.dark => (
                const [Color(0xFF1E1A16), Color(0xFF1E1A16)],
                s.widgetThemeDark,
              ),
            WidgetTheme.brand => (
                const [Color(0xFF6B1F2A), Color(0xFF6B1F2A)],
                s.widgetThemeBrand,
              ),
          };

          return GestureDetector(
            onTap: () => onPick(theme),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 46,
                    width: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : mutedColor.withValues(alpha: 0.25),
                        width: isSelected ? 2 : 1,
                      ),
                      // Two halves for `auto`, one flat colour for the rest —
                      // the split square is the clearest way to say "whichever
                      // the launcher is".
                      gradient: LinearGradient(
                        colors: swatch,
                        stops: const [0.5, 0.5],
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            size: 18, color: accentColor)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicCaption.copyWith(
                      color: isSelected ? accentColor : textColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onPick,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onPick(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == selected
                        ? accentColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelOf(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicCaption.copyWith(
                      color: value == selected ? accentColor : mutedColor,
                      fontWeight: value == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({
    required this.value,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
    required this.onSettled,
  });

  final int value;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSettled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                overlayColor: accentColor.withValues(alpha: 0.12),
              ),
              child: Slider(
                // All the way to nothing: at 0 the card disappears and the
                // text stands on the wallpaper, which is the transparent
                // widget people ask for. Only the card fades, never the text.
                min: 0,
                max: 100,
                divisions: 20,
                value: value.toDouble(),
                onChanged: (v) => onChanged(v.round()),
                onChangeEnd: (v) => onSettled(v.round()),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value%',
              textAlign: TextAlign.end,
              style: AppTypography.englishCaption.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color textColor;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.amharicLabel.copyWith(color: textColor),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

/// The streak emoji picker, on the streak widget's own page section.
///
/// The value is drawn by the launcher's system emoji font, so the choices are
/// a closed set — see [kStreakEmojiChoices].
class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.selected,
    required this.surfaceColor,
    required this.accentColor,
    required this.onPick,
  });

  final String selected;
  final Color surfaceColor;
  final Color accentColor;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kStreakEmojiChoices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final emoji = kStreakEmojiChoices[i];
        final isSelected = emoji == selected;
        return InkWell(
          onTap: () => onPick(emoji),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      },
    );
  }
}

// ── Small shared pieces ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        text,
        style: AppTypography.amharicCaption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.amharicCaption.copyWith(
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
