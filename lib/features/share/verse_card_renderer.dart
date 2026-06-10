import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../books/presentation/widgets/reader/constants.dart';
import 'verse_card_models.dart';
import 'verse_card_state.dart';

class VerseCardRenderer extends StatelessWidget {
  final VerseCardState state;
  final String verseText;
  final String reference;

  const VerseCardRenderer({
    super.key,
    required this.state,
    required this.verseText,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = state.textColorMode.color;
    final fontName = readerFonts[state.fontIndex.clamp(0, readerFonts.length - 1)];

    return AspectRatio(
      aspectRatio: state.aspectRatio.value,
      child: Container(
        decoration: _buildBackgroundDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gallery image if applicable
            if (state.bgType == CardBgType.galleryImage && state.galleryImagePath != null) ...[
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Image.file(
                    File(state.galleryImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
                  ),
                ),
              ),
              // Opacity overlay slider-controlled
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: state.overlayOpacity),
                ),
              ),
            ],

            // Decorative Frame Overlay
            if (state.frameStyle != CardFrameStyle.none)
              Positioned.fill(
                child: CustomPaint(
                  painter: CardFramePainter(
                    style: state.frameStyle,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),

            // Content + watermark as a single flow so Expanded centers
            // verse text in only the space above the watermark.
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              verseText,
                              textAlign: state.textAlign,
                              style: TextStyle(
                                fontFamily: fontName,
                                fontSize: state.fontSize,
                                color: textColor,
                                height: 1.5,
                                shadows: state.textColorMode == CardTextColorMode.light
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          offset: const Offset(0, 1.5),
                                          blurRadius: 3.0,
                                        )
                                      ]
                                    : null,
                              ),
                            ),

                            if (state.showReference) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: 40,
                                height: 1,
                                color: textColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                reference,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontName,
                                  fontSize: (state.fontSize - 4).clamp(12.0, 24.0),
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.85),
                                  letterSpacing: 0.5,
                                  shadows: state.textColorMode == CardTextColorMode.light
                                      ? [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2.0,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Watermark in flow — Expanded above sizes to the space
                  // above this, so FittedBox centers content correctly.
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Opacity(
                        opacity: 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3.0),
                          child: Image.asset(
                            'assets/eotc.jpg',
                            width: 14,
                            height: 14,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nehemiyah',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: textColor.withValues(alpha: 0.6),
                          shadows: state.textColorMode == CardTextColorMode.light
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2.0,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    switch (state.bgType) {
      case CardBgType.solid:
        final color = VerseCardPresets.solidColors[state.solidColorIndex];
        return BoxDecoration(color: color);
      case CardBgType.gradient:
        final gradient = VerseCardPresets.gradients[state.gradientIndex];
        return BoxDecoration(gradient: gradient);
      case CardBgType.galleryImage:
        // Handled as stack child
        return const BoxDecoration(color: Colors.black);
    }
  }
}

class CardFramePainter extends CustomPainter {
  final CardFrameStyle style;
  final Color color;

  CardFramePainter({required this.style, required this.color});

  @override
  @override
void paint(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  const double watermarkClearance = 36.0;

  if (style == CardFrameStyle.line) {
    final rect = Rect.fromLTRB(16, 16, size.width - 16, size.height - watermarkClearance);
    canvas.drawRect(rect, paint);
  }
  else if (style == CardFrameStyle.ornate) {
    final double margin = 24.0;
    final double starRadius = 6.0;
    final double dotSpacing = 8.0;
    final double dotRadius = 1.5;

    final topLeft = Offset(margin, margin);
    final topRight = Offset(size.width - margin, margin);
    final bottomLeft = Offset(margin, size.height - watermarkClearance);
    final bottomRight = Offset(size.width - margin, size.height - watermarkClearance);

    // Draw 4-pointed stars
    void drawStar(Offset center) {
      final path = Path();
      path.moveTo(center.dx, center.dy - starRadius);
      path.quadraticBezierTo(center.dx, center.dy, center.dx + starRadius, center.dy);
      path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + starRadius);
      path.quadraticBezierTo(center.dx, center.dy, center.dx - starRadius, center.dy);
      path.close();
      
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    drawStar(topLeft);
    drawStar(topRight);
    drawStar(bottomLeft);
    drawStar(bottomRight);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;

    void drawDot(Offset offset) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, dotRadius, fillPaint);
    }

    // Top Edge
    drawDot(Offset(topLeft.dx + dotSpacing * 1.5, topLeft.dy));
    drawDot(Offset(topLeft.dx + dotSpacing * 3, topLeft.dy));
    drawDot(Offset(topRight.dx - dotSpacing * 1.5, topRight.dy));
    drawDot(Offset(topRight.dx - dotSpacing * 3, topRight.dy));
    canvas.drawLine(
        Offset(topLeft.dx + dotSpacing * 4.5, topLeft.dy),
        Offset(topRight.dx - dotSpacing * 4.5, topRight.dy), paint);

    // Bottom Edge
    drawDot(Offset(bottomLeft.dx + dotSpacing * 1.5, bottomLeft.dy));
    drawDot(Offset(bottomLeft.dx + dotSpacing * 3, bottomLeft.dy));
    drawDot(Offset(bottomRight.dx - dotSpacing * 1.5, bottomRight.dy));
    drawDot(Offset(bottomRight.dx - dotSpacing * 3, bottomRight.dy));
    canvas.drawLine(
        Offset(bottomLeft.dx + dotSpacing * 4.5, bottomLeft.dy),
        Offset(bottomRight.dx - dotSpacing * 4.5, bottomRight.dy), paint);

    // Left Edge
    drawDot(Offset(topLeft.dx, topLeft.dy + dotSpacing * 1.5));
    drawDot(Offset(topLeft.dx, topLeft.dy + dotSpacing * 3));
    drawDot(Offset(bottomLeft.dx, bottomLeft.dy - dotSpacing * 1.5));
    drawDot(Offset(bottomLeft.dx, bottomLeft.dy - dotSpacing * 3));
    canvas.drawLine(
        Offset(topLeft.dx, topLeft.dy + dotSpacing * 4.5),
        Offset(bottomLeft.dx, bottomLeft.dy - dotSpacing * 4.5), paint);

    // Right Edge
    drawDot(Offset(topRight.dx, topRight.dy + dotSpacing * 1.5));
    drawDot(Offset(topRight.dx, topRight.dy + dotSpacing * 3));
    drawDot(Offset(bottomRight.dx, bottomRight.dy - dotSpacing * 1.5));
    drawDot(Offset(bottomRight.dx, bottomRight.dy - dotSpacing * 3));
    canvas.drawLine(
        Offset(topRight.dx, topRight.dy + dotSpacing * 4.5),
        Offset(bottomRight.dx, bottomRight.dy - dotSpacing * 4.5), paint);
  } 
  else if (style == CardFrameStyle.manuscript) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;

    final path = Path();
    final margin = 20.0;
    
    // Top scroll roll
    path.moveTo(margin, margin + 15);
    path.quadraticBezierTo(size.width / 2, margin - 15, size.width - margin, margin + 15);
    
    // Right wavy edge
    path.quadraticBezierTo(size.width - margin + 8, size.height / 3, size.width - margin - 4, size.height / 2);
    path.quadraticBezierTo(size.width - margin + 6, size.height * 2 / 3, size.width - margin, size.height - margin - 15);

    final bottomY = size.height - watermarkClearance;

    // Bottom scroll roll
    path.quadraticBezierTo(size.width / 2, bottomY + 15, margin, bottomY - 15);

    // Left wavy edge
    path.quadraticBezierTo(margin - 8, size.height * 2 / 3, margin + 4, size.height / 2);
    path.quadraticBezierTo(margin - 6, size.height / 3, margin, margin + 15);

    canvas.drawPath(path, paint);

    // Inner scroll lines (curls)
    final innerPath = Path();
    innerPath.moveTo(margin, margin + 15);
    innerPath.quadraticBezierTo(margin + 15, margin + 25, margin + 30, margin + 10);

    innerPath.moveTo(size.width - margin, margin + 15);
    innerPath.quadraticBezierTo(size.width - margin - 15, margin + 25, size.width - margin - 30, margin + 10);

    innerPath.moveTo(margin, bottomY - 15);
    innerPath.quadraticBezierTo(margin + 15, bottomY - 25, margin + 30, bottomY - 10);

    innerPath.moveTo(size.width - margin, bottomY - 15);
    innerPath.quadraticBezierTo(size.width - margin - 15, bottomY - 25, size.width - margin - 30, bottomY - 10);

    paint.strokeWidth = 1.0;
    canvas.drawPath(innerPath, paint);
  }
}
  
  

  @override
  bool shouldRepaint(covariant CardFramePainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}
