import 'package:flutter/material.dart';

enum CardAspectRatio {
  square(1.0, '1:1'),
  portrait(0.8, '4:5'),
  story(9 / 16, '9:16');

  final double value;
  final String label;
  const CardAspectRatio(this.value, this.label);
}

enum CardBgType {
  solid,
  gradient,
  galleryImage,
}

enum CardFrameStyle {
  none,
  line,
  ornate,
  manuscript,
}

enum CardTextColorMode {
  light(Colors.white, 'Light'),
  dark(Color(0xFF2C2C2C), 'Dark');

  final Color color;
  final String label;
  const CardTextColorMode(this.color, this.label);
}

class VerseCardPresets {
  static const List<Color> solidColors = [
    Color(0xFF1E352F), // Dark Green
    Color(0xFF14213D), // Deep Navy Blue
    Color(0xFF4A121A), // Burgundy
    Color(0xFF121212), // Matte Black
    Color(0xFFF7F5F0), // Ivory
    Color(0xFF2E3D52), // Slate Gray
    Color(0xFF0F4C5C), // Dark Teal
    Color(0xFF386641), // Olive
    Color(0xFFB5838D), // Warm Rose/Taupe
    Color(0xFFE5D5C5), // Warm Parchment
  ];

  static const List<List<Color>> gradientPresets = [
    [Color(0xFFFF9E00), Color(0xFFFF007F)], // Dawn
    [Color(0xFF3D30A2), Color(0xFFB15EFF)], // Dusk
    [Color(0xFF134E5E), Color(0xFF71B280)], // Forest
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Night Sky
    [Color(0xFFEFEFBB), Color(0xFFD4D3DD)], // Parchment/Silver
  ];

  static List<LinearGradient> get gradients => gradientPresets.map((colors) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }).toList();
}
