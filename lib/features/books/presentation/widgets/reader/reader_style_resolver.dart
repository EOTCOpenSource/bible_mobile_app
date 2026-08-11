import 'package:flutter/material.dart';

/// Helper for computing verse typography styles, body padding, and text alignment
/// from reader settings. Extracted so other reading views (prayer, Synaxarium, etc.)
/// can reuse the identical typography rules.
class ReaderStyleResolver {
  const ReaderStyleResolver._();

  static const double baseHorizontalPadding = 20.0;
  static const double minJustifyScreenWidth = 340.0;

  static const double minFontSize = 12.0;
  static const double maxFontSize = 48.0;
  static const double minSystemScale = 0.85;
  static const double maxSystemScale = 1.60;

  /// Computes the horizontal padding for the chapter body container.
  static EdgeInsets computeBodyPadding({
    required double marginScale,
    double top = 0,
    double bottom = 0,
  }) {
    final horizontal = baseHorizontalPadding * marginScale;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  /// Computes the body [TextStyle] for verse rendering.
  static TextStyle computeBodyStyle({
    required String fontFamily,
    required double fontSize,
    required double lineHeight,
    required Color textColor,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    TextScaler? textScaler,
  }) {
    final clampedBase = fontSize.clamp(minFontSize, maxFontSize);
    final effectiveSize = textScaler != null
        ? textScaler.scale(clampedBase).clamp(minFontSize, maxFontSize)
        : clampedBase;

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: effectiveSize,
      height: lineHeight,
      color: textColor,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }

  /// Clamps a system text scale factor to safe bounds (0.85 .. 1.60).
  static double clampTextScale(double scale) {
    return scale.clamp(minSystemScale, maxSystemScale);
  }

  /// Maps [textAlign] integer (0: start, 1: justify) to [TextAlign].
  ///
  /// Automatically falls back to [TextAlign.start] if [screenWidth] is below
  /// [minJustifyScreenWidth] to avoid awkward word spacing in Ethiopic script.
  static TextAlign computeTextAlign({
    required int textAlign,
    double? screenWidth,
  }) {
    if (textAlign == 1) {
      if (screenWidth != null && screenWidth < minJustifyScreenWidth) {
        return TextAlign.start;
      }
      return TextAlign.justify;
    }
    return TextAlign.start;
  }
}
