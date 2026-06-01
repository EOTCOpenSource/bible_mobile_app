import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ornate top divider decoration for premium look
                    if (state.frameStyle == CardFrameStyle.ornate || state.frameStyle == CardFrameStyle.manuscript) ...[
                      Icon(
                        Icons.brightness_5_outlined,
                        size: 16,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Flexible(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Text(
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
                      ),
                    ),

                    if (state.showReference) ...[
                      const SizedBox(height: 20),
                      // Decorative line above reference
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

  if (style == CardFrameStyle.line) {
    final rect = Rect.fromLTRB(16, 16, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);
  } 
  else if (style == CardFrameStyle.ornate) {
    final outerRect = Rect.fromLTRB(16, 16, size.width - 16, size.height - 16);
    final innerRect = Rect.fromLTRB(22, 22, size.width - 22, size.height - 22);

    paint.strokeWidth = 1.0;
    canvas.drawRect(outerRect, paint);

    paint.strokeWidth = 0.5;
    canvas.drawRect(innerRect, paint);

    paint.strokeWidth = 1.5;

    // Top Left
    canvas.drawLine(Offset(10, 16), Offset(28, 16), paint);
    canvas.drawLine(Offset(16, 10), Offset(16, 28), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width - 10, 16),
      Offset(size.width - 28, 16),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 16, 10),
      Offset(size.width - 16, 28),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(10, size.height - 16),
      Offset(28, size.height - 16),
      paint,
    );
    canvas.drawLine(
      Offset(16, size.height - 10),
      Offset(16, size.height - 28),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - 10, size.height - 16),
      Offset(size.width - 28, size.height - 16),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 16, size.height - 10),
      Offset(size.width - 16, size.height - 28),
      paint,
    );
  } 
  else if (style == CardFrameStyle.manuscript) {
    paint.strokeWidth = 2.0;

    final rect = Rect.fromLTRB(20, 20, size.width - 20, size.height - 20);
    canvas.drawRect(rect, paint);

    paint.strokeWidth = 1.0;

    // Top-left
    canvas.drawLine(Offset(14, 14), Offset(32, 14), paint);
    canvas.drawLine(Offset(14, 14), Offset(14, 32), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - 14, 14),
      Offset(size.width - 32, 14),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 14, 14),
      Offset(size.width - 14, 32),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(14, size.height - 14),
      Offset(32, size.height - 14),
      paint,
    );
    canvas.drawLine(
      Offset(14, size.height - 14),
      Offset(14, size.height - 32),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - 14, size.height - 14),
      Offset(size.width - 32, size.height - 14),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 14, size.height - 14),
      Offset(size.width - 14, size.height - 32),
      paint,
    );
  }
}
  
  

  @override
  bool shouldRepaint(covariant CardFramePainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.color != color;
  }
}
