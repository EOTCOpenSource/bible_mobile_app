import 'package:flutter/material.dart';
import 'verse_card_models.dart';

class VerseCardState {
  final CardBgType bgType;
  final int solidColorIndex;
  final int gradientIndex;
  final String? galleryImagePath;
  final CardFrameStyle frameStyle;
  final int fontIndex;
  final double fontSize;
  final CardTextColorMode textColorMode;
  final TextAlign textAlign;
  final bool showReference;
  final bool useGeezRef;
  final bool useAmharicBookName;
  final CardAspectRatio aspectRatio;
  final double overlayOpacity;

  const VerseCardState({
    required this.bgType,
    required this.solidColorIndex,
    required this.gradientIndex,
    this.galleryImagePath,
    required this.frameStyle,
    required this.fontIndex,
    required this.fontSize,
    required this.textColorMode,
    required this.textAlign,
    required this.showReference,
    required this.useGeezRef,
    required this.useAmharicBookName,
    required this.aspectRatio,
    required this.overlayOpacity,
  });

  factory VerseCardState.initial({
    required int initialBgType,
    required int initialSolidColorIndex,
    required int initialGradientIndex,
    required int initialFrameStyleIndex,
    required int initialFontIndex,
    required int initialAspectRatioIndex,
    required bool defaultGeez,
    required bool defaultAmharic,
  }) {
    return VerseCardState(
      bgType: CardBgType.values[initialBgType.clamp(0, CardBgType.values.length - 1)],
      solidColorIndex: initialSolidColorIndex.clamp(0, VerseCardPresets.solidColors.length - 1),
      gradientIndex: initialGradientIndex.clamp(0, VerseCardPresets.gradients.length - 1),
      frameStyle: CardFrameStyle.values[initialFrameStyleIndex.clamp(0, CardFrameStyle.values.length - 1)],
      fontIndex: initialFontIndex,
      fontSize: 20.0,
      textColorMode: CardTextColorMode.light,
      textAlign: TextAlign.center,
      showReference: true,
      useGeezRef: defaultGeez,
      useAmharicBookName: defaultAmharic,
      aspectRatio: CardAspectRatio.values[initialAspectRatioIndex.clamp(0, CardAspectRatio.values.length - 1)],
      overlayOpacity: 0.35,
    );
  }

  VerseCardState copyWith({
    CardBgType? bgType,
    int? solidColorIndex,
    int? gradientIndex,
    String? galleryImagePath,
    CardFrameStyle? frameStyle,
    int? fontIndex,
    double? fontSize,
    CardTextColorMode? textColorMode,
    TextAlign? textAlign,
    bool? showReference,
    bool? useGeezRef,
    bool? useAmharicBookName,
    CardAspectRatio? aspectRatio,
    double? overlayOpacity,
  }) {
    return VerseCardState(
      bgType: bgType ?? this.bgType,
      solidColorIndex: solidColorIndex ?? this.solidColorIndex,
      gradientIndex: gradientIndex ?? this.gradientIndex,
      galleryImagePath: galleryImagePath ?? this.galleryImagePath,
      frameStyle: frameStyle ?? this.frameStyle,
      fontIndex: fontIndex ?? this.fontIndex,
      fontSize: fontSize ?? this.fontSize,
      textColorMode: textColorMode ?? this.textColorMode,
      textAlign: textAlign ?? this.textAlign,
      showReference: showReference ?? this.showReference,
      useGeezRef: useGeezRef ?? this.useGeezRef,
      useAmharicBookName: useAmharicBookName ?? this.useAmharicBookName,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
    );
  }
}
