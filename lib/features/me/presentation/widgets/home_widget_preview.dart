import 'package:flutter/material.dart';

import '../../../../core/home_widget/home_widget_data.dart';
import '../../../../core/home_widget/widget_appearance.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The palette one [WidgetTheme] resolves to, in Flutter terms.
///
/// The Kotlin side has the same three palettes in `WidgetStyle.kt`, built from
/// the hex values in `values/widget_colors.xml`. Both are mirrors of
/// [AppColorScheme] — this one takes them from the scheme directly, which is
/// what keeps the preview honest: if the app's maroon changes, the preview
/// changes with it and the XML is the only copy left to update.
@immutable
class _PreviewPalette {
  const _PreviewPalette({
    required this.card,
    required this.text,
    required this.muted,
    required this.accent,
    required this.track,
    required this.border,
    required this.isBrand,
  });

  final Color card;
  final Color text;
  final Color muted;
  final Color accent;
  final Color track;
  final Color border;
  final bool isBrand;

  static _PreviewPalette of(WidgetTheme theme, {required bool systemDark}) {
    final resolved = theme == WidgetTheme.auto
        ? (systemDark ? WidgetTheme.dark : WidgetTheme.light)
        : theme;

    return switch (resolved) {
      WidgetTheme.brand => _PreviewPalette(
          card: AppColorScheme.light.primary,
          text: AppColorScheme.light.textOnDark,
          muted: AppColorScheme.light.accent.withValues(alpha: 0.70),
          accent: AppColorScheme.light.accent,
          track: AppColorScheme.light.primaryLight,
          border: AppColorScheme.light.accent.withValues(alpha: 0.20),
          isBrand: true,
        ),
      WidgetTheme.dark => _PreviewPalette(
          card: AppColorScheme.dark.parchment,
          text: AppColorScheme.dark.textOnParchment,
          muted: AppColorScheme.dark.textMuted,
          accent: AppColorScheme.dark.accentDark,
          track: AppColorScheme.dark.divider,
          border: AppColorScheme.dark.borderSubtle,
          isBrand: false,
        ),
      // `auto` has already been resolved to one of the two above.
      _ => _PreviewPalette(
          card: AppColorScheme.light.surface,
          text: AppColorScheme.light.textOnParchment,
          muted: AppColorScheme.light.textMuted,
          accent: AppColorScheme.light.primary,
          track: AppColorScheme.light.parchmentDark,
          border: AppColorScheme.light.borderSubtle,
          isBrand: false,
        ),
    };
  }
}

/// The base text sizes each widget is drawn at, in sp — the same numbers the
/// Kotlin providers use at their reference size, so a preview at the default
/// text scale is what the widget actually renders on a default-sized cell.
class _Sizes {
  static const verseLabel = 11.0;
  static const verseShortRef = 9.0;
  static const verseText = 14.0;
  static const verseRef = 12.0;

  static const continueLabel = 10.0;
  static const continueBook = 16.0;
  static const continueRef = 12.0;

  static const streakEmoji = 30.0;
  static const streakCount = 26.0;
  static const streakLabel = 12.0;
}

/// One Android home screen widget, drawn in Flutter.
///
/// Every setting on the widgets page changes something the user cannot see
/// until they look at their home screen — theme, text size, background
/// opacity, which rows are visible. A preview is what makes those settings
/// adjustable rather than guessable, so it is drawn from the same numbers and
/// the same content the real widget gets: today's verse, the book actually
/// left off at, the streak actually standing.
///
/// It cannot be a screenshot of the real thing — the launcher renders widgets
/// in its own process and there is no API to ask it for a picture — so this is
/// a deliberate second implementation. The comment blocks in `WidgetStyle.kt`
/// and the sizes in [_Sizes] are the two places to keep it in step.
class HomeWidgetPreview extends StatelessWidget {
  const HomeWidgetPreview({
    super.key,
    required this.kind,
    required this.style,
    required this.data,
    required this.s,
    required this.systemDark,
  });

  final HomeWidgetKind kind;
  final WidgetStyle style;

  /// The real widget payload, or null while it is still being read.
  final HomeWidgetData? data;

  final AppStrings s;

  /// What `auto` resolves to — the app's own dark mode, since that is the
  /// setting the user has in front of them.
  final bool systemDark;

  @override
  Widget build(BuildContext context) {
    final palette = _PreviewPalette.of(style.theme, systemDark: systemDark);
    final scale = style.textScale.factor;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The default cell footprint of each widget, so the preview is cut to
        // the same proportions the launcher hands it. Rounded generously on
        // the tall side: a launcher row is nearer 100dp than the 70dp the
        // widget metadata asks for, and a preview that is tighter than the
        // real thing would report overflow the home screen never sees.
        final (width, aspect) = switch (kind) {
          HomeWidgetKind.dailyVerse => (constraints.maxWidth, 250 / 122),
          HomeWidgetKind.continueReading => (constraints.maxWidth, 250 / 104),
          HomeWidgetKind.streak => (156.0, 1.0),
        };

        return Center(
          child: SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Only the card carries the opacity, exactly as on Android:
                  // `setImageAlpha` fades the background ImageView and nothing
                  // above it, so text stays fully opaque at every setting.
                  Opacity(
                    opacity: style.opacity / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: palette.border),
                      ),
                    ),
                  ),
                  if (palette.isBrand)
                    Positioned(
                      top: -64,
                      right: -48,
                      child: Opacity(
                        opacity: style.opacity / 100,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: switch (kind) {
                      HomeWidgetKind.dailyVerse =>
                        _versePreview(palette, scale),
                      HomeWidgetKind.continueReading =>
                        _continuePreview(palette, scale),
                      HomeWidgetKind.streak => _streakPreview(palette, scale),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _versePreview(_PreviewPalette p, double scale) {
    final text = data?.verseText ?? '';
    if (text.isEmpty) {
      return _emptyState(p, s.widgetEmptyVerse, scale);
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showLabel)
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.dailyVerseTag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicCaption.copyWith(
                      color: p.accent,
                      fontSize: _Sizes.verseLabel * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data?.verseRefShort ?? '',
                  maxLines: 1,
                  style: AppTypography.englishCaption.copyWith(
                    color: p.muted,
                    fontSize: _Sizes.verseShortRef * scale,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (style.showLabel) const SizedBox(height: 10),
          // Centred in the leftover height, as `gravity="center_vertical"`
          // does on the widget itself — the amount left over is what changes
          // when the card is resized, so a top-aligned verse is the thing that
          // makes one size look balanced and another top-heavy.
          //
          // The line count is measured the way DailyVerseWidget.kt measures
          // it, because centring only works once the text is allowed to be
          // shorter than its box: a verse stretched to fill the height has no
          // slack to be centred in.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fontSize = _Sizes.verseText * scale;
                final lines = (constraints.maxHeight / (fontSize * 1.35))
                    .floor()
                    .clamp(1, 14);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicVerse.copyWith(
                      color: p.text,
                      height: 1.35,
                      fontSize: fontSize,
                    ),
                  ),
                );
              },
            ),
          ),
          if (style.showDetail) ...[
            const SizedBox(height: 8),
            Text(
              data?.verseRef ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.amharicLabel.copyWith(
                color: p.accent,
                fontSize: _Sizes.verseRef * scale,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _continuePreview(_PreviewPalette p, double scale) {
    final book = data?.continueBook ?? '';
    if (book.isEmpty) {
      return _emptyState(p, s.widgetEmptyContinue, scale);
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (style.showLabel)
            Text(
              s.continueReadingTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.amharicCaption.copyWith(
                color: p.muted,
                fontSize: _Sizes.continueLabel * scale,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            book,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicLabel.copyWith(
              color: p.text,
              fontSize: _Sizes.continueBook * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            data?.continueRef ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicCaption.copyWith(
              color: p.accent,
              fontSize: _Sizes.continueRef * scale,
            ),
          ),
          if (style.showDetail) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (data?.continueProgress ?? 0) / 100,
                minHeight: 6,
                backgroundColor: p.track,
                valueColor: AlwaysStoppedAnimation<Color>(p.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _streakPreview(_PreviewPalette p, double scale) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (style.showDetail)
            Text(
              data?.streakEmoji ?? '🔥',
              style: TextStyle(fontSize: _Sizes.streakEmoji),
            ),
          const SizedBox(height: 4),
          Text(
            data?.streakCountLabel ?? '0',
            maxLines: 1,
            style: AppTypography.amharicHeading.copyWith(
              color: p.text,
              fontSize: _Sizes.streakCount * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (style.showLabel)
            Text(
              data?.streakSuffix ?? s.streakDaysSuffix,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.amharicCaption.copyWith(
                color: p.muted,
                fontSize: _Sizes.streakLabel * scale,
              ),
            ),
        ],
      ),
    );
  }

  /// What the widget shows before the app has ever run, or when the verse
  /// could not be resolved — previewed rather than hidden, because it is the
  /// state a brand new user sees first.
  Widget _emptyState(_PreviewPalette p, String message, double scale) => Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.amharicBody.copyWith(
              color: p.muted,
              fontSize: 13 * scale,
            ),
          ),
        ),
      );
}
