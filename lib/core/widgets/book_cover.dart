import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A closed Bible book cover widget.
///
/// [coverColor] is the main face/back colour.
/// [coverDarkColor] is the spine shadow colour (defaults to a darker shade of [coverColor]).
/// [width] / [height] control the cover face size (defaults match the continue-reading card).
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    this.coverColor,
    this.coverDarkColor,
    this.width = 56,
    this.height = 84,
    this.title,
    this.subtitle,
  });

  final Color? coverColor;
  final Color? coverDarkColor;
  final double width;
  final double height;

  /// Set on the face under the cross, e.g. a short book name.
  ///
  /// With no title the cross stays centred, which is how every plain cover in
  /// the app already looks. With one, the face becomes a title block — cross,
  /// then name, then [subtitle] — so the three read top to bottom instead of
  /// competing for the middle.
  final String? title;

  /// A line under [title], e.g. the chapter you are on. Ignored without a title.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final face = coverColor ?? c.primary;
    final dark = coverDarkColor ?? _darken(face);
    final accent = c.accent;
    final pageEdge1 = c.surface;
    const pageEdge2 = Color(0xFFE6DFD3);

    return SizedBox(
      width: width + 10,
      height: height + 10,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
              bottomLeft: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [dark, face, face],
              stops: const [0, 0.12, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: Offset(width * 0.125, height * 0.12),
                blurRadius: 12,
              ),
              BoxShadow(color: face, offset: const Offset(4, 4)),
              BoxShadow(color: pageEdge2, offset: const Offset(3, 3)),
              BoxShadow(color: pageEdge1, offset: const Offset(2, 2)),
              BoxShadow(color: pageEdge2, offset: const Offset(1.5, 1.5)),
              BoxShadow(color: pageEdge1, offset: const Offset(1, 1)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Spine shadow
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width * 0.285,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Spine groove
              Positioned(
                left: width * 0.09,
                top: 0,
                bottom: 0,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0DFFFFFF),
                        offset: Offset(1, 0),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Gold inlay border
              Positioned(
                left: width * 0.16,
                top: 4,
                right: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                      bottomLeft: Radius.circular(2),
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Cross, alone or heading the title block.
              if (title == null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: width * 0.07),
                    child: CustomPaint(
                      size: Size(width * 0.285, height * 0.262),
                      painter: _CrossPainter(color: accent),
                    ),
                  ),
                )
              else
                Positioned(
                  left: width * 0.16,
                  top: 6,
                  right: 5,
                  bottom: 6,
                  child: _TitleBlock(
                    title: title!,
                    subtitle: subtitle,
                    width: width,
                    height: height,
                    accent: accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}

/// Cross above, name below, chapter last — centred in the gold inlay.
///
/// Type sizes come off the cover width so a tile that shrinks with the strip
/// keeps its proportions rather than turning into a caption under a big cross.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.width,
    required this.height,
    required this.accent,
  });

  final String title;
  final String? subtitle;
  final double width;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final titleSize = (width * 0.135).clamp(9.0, 15.0);
    final subtitleSize = (width * 0.105).clamp(8.0, 12.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(width * 0.22, height * 0.19),
          painter: _CrossPainter(color: accent),
        ),
        SizedBox(height: height * 0.055),
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicLabel.copyWith(
              color: accent,
              fontSize: titleSize,
              height: 1.2,
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: height * 0.02),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicCaption.copyWith(
              color: accent.withValues(alpha: 0.72),
              fontSize: subtitleSize,
            ),
          ),
        ],
      ],
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 24;
    final sy = h / 32;
    final stroke = 3 * ((sx + sy) / 2).clamp(1.8, 3.2);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(12 * sx, 2 * sy), Offset(12 * sx, 30 * sy), paint);
    canvas.drawLine(Offset(2 * sx, 10 * sy), Offset(22 * sx, 10 * sy), paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter old) => old.color != color;
}

/// Infers the testament colour from a book name (kebab or title-case).
Color testamentColor(String bookName) {
  final key = bookName.toLowerCase().replaceAll(' ', '-').replaceAll('_', '-');
  if (_ntKeys.contains(key)) return AppColors.newTestament;
  if (_deutKeys.contains(key)) return const Color(0xFF3E5C3A); // dark olive
  return AppColors.oldTestament;
}

Color testamentDarkColor(String bookName) {
  final c = testamentColor(bookName);
  return HSLColor.fromColor(c)
      .withLightness(
          (HSLColor.fromColor(c).lightness - 0.15).clamp(0.0, 1.0))
      .toColor();
}

const _ntKeys = {
  'matthew', 'mark', 'luke', 'john', 'acts', 'romans',
  '1-corinthians', '2-corinthians', 'galatians', 'ephesians',
  'philippians', 'colossians', '1-thessalonians', '2-thessalonians',
  '1-timothy', '2-timothy', 'titus', 'philemon', 'hebrews',
  'james', '1-peter', '2-peter', '1-john', '2-john', '3-john',
  'jude', 'revelation',
};

const _deutKeys = {
  'jubilees', 'enoch', 'book-of-tobit', 'book-of-judith',
  '1-maccabees', '2-maccabees', '3-maccabees',
  'wisdom-of-solomon', 'book-of-sirach', 'baruch',
  'thr-letter-of-jeremiah', 'teref-baruch',
  '3-book-of-ezra', '2nd-book-of-ezra',
};
