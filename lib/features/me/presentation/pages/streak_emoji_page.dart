import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/providers/reading_progress_providers.dart';

/// Picks the emoji shown beside the reading streak.
///
/// The choice reaches three surfaces — the home header pill, the streak page
/// and the Android streak widget — so the preview here is drawn from the
/// user's *real* current streak rather than a made-up number. Seeing "🔥 0"
/// when the streak is broken is the honest preview; a decorative "🔥 12" would
/// promise a widget that says something else.
class StreakEmojiPage extends ConsumerWidget {
  const StreakEmojiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          s.streakEmojiTitle,
          style: AppTypography.amharicSubheading.copyWith(color: textColor),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _PreviewCard(
            emoji: settings.streakEmoji,
            useGeez: settings.useGeezNumbers,
            daysSuffix: s.streakDaysSuffix,
            previewLabel: s.streakEmojiPreviewLabel,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 24),
          Text(
            s.streakEmojiSectionChoose,
            style: AppTypography.amharicCaption.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _EmojiGrid(
            selected: settings.streakEmoji,
            surfaceColor: surfaceColor,
            accentColor: accentColor,
            mutedColor: mutedColor,
            onPick: (emoji) => Settings.update(
              context,
              settings.copyWith(streakEmoji: emoji),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.widgets_outlined, size: 15, color: mutedColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.streakEmojiWidgetNote,
                  style: AppTypography.amharicCaption.copyWith(
                    color: mutedColor,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The streak pill as the rest of the app draws it, at the chosen emoji.
class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({
    required this.emoji,
    required this.useGeez,
    required this.daysSuffix,
    required this.previewLabel,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
  });

  final String emoji;
  final bool useGeez;
  final String daysSuffix;
  final String previewLabel;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A missing or still-loading streak previews as zero rather than as a
    // spinner: the point of this card is the emoji, and a card that reflows
    // when the query lands makes picking one feel unsteady.
    final count = ref.watch(readingStreakStateProvider).maybeWhen(
          data: (state) => state.currentStreak,
          orElse: () => 0,
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            previewLabel,
            style: AppTypography.amharicCaption.copyWith(
              color: mutedColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(emoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 6),
          Text(
            useGeez ? toGeez(count) : '$count',
            style: AppTypography.amharicHeading.copyWith(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            daysSuffix,
            style: AppTypography.amharicCaption.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.selected,
    required this.surfaceColor,
    required this.accentColor,
    required this.mutedColor,
    required this.onPick,
  });

  final String selected;
  final Color surfaceColor;
  final Color accentColor;
  final Color mutedColor;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kStreakEmojiChoices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        final emoji = kStreakEmojiChoices[i];
        final isSelected = emoji == selected;
        return InkWell(
          onTap: () => onPick(emoji),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }
}
