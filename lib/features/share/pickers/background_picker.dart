import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/l10n/l10n.dart';
import '../verse_card_models.dart';
import '../verse_card_state.dart';

class BackgroundPicker extends StatelessWidget {
  final VerseCardState state;
  final ValueChanged<VerseCardState> onChanged;

  const BackgroundPicker({
    super.key,
    required this.state,
    required this.onChanged,
  });

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onChanged(state.copyWith(
          bgType: CardBgType.galleryImage,
          galleryImagePath: image.path,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).cardImagePickFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Background Type Selector
          Row(
            children: [
              _buildTypeButton(context, CardBgType.solid, s.cardBgColours),
              const SizedBox(width: 8),
              _buildTypeButton(context, CardBgType.gradient, s.cardBgGradients),
              const SizedBox(width: 8),
              _buildTypeButton(context, CardBgType.galleryImage, s.cardBgGallery),
            ],
          ),
          const SizedBox(height: 16),

          // Sub-options based on selected type
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildSubPicker(context, s),
          ),
          const SizedBox(height: 20),

          // Frame Section
          Text(
            s.cardBgFrame,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CardFrameStyle.values.map((frame) {
                final isSelected = state.frameStyle == frame;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_getFrameLabel(frame, s)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) onChanged(state.copyWith(frameStyle: frame));
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, CardBgType type, String label) {
    final isSelected = state.bgType == type;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => onChanged(state.copyWith(bgType: type)),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSubPicker(BuildContext context, dynamic s) {
    switch (state.bgType) {
      case CardBgType.solid:
        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: VerseCardPresets.solidColors.length,
            itemBuilder: (context, index) {
              final color = VerseCardPresets.solidColors[index];
              final isSelected = state.solidColorIndex == index;
              return GestureDetector(
                onTap: () => onChanged(state.copyWith(solidColorIndex: index)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.6 ? Colors.black : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        );

      case CardBgType.gradient:
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: VerseCardPresets.gradients.length,
            itemBuilder: (context, index) {
              final gradient = VerseCardPresets.gradients[index];
              final isSelected = state.gradientIndex == index;
              return GestureDetector(
                onTap: () => onChanged(state.copyWith(gradientIndex: index)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  width: 60,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        );

      case CardBgType.galleryImage:
        return Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.photo_library),
                  label: Text(s.cardBgGallery),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                if (state.galleryImagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(state.galleryImagePath!),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.galleryImagePath!.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
            if (state.galleryImagePath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.blur_on, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: state.overlayOpacity,
                      min: 0.0,
                      max: 0.9,
                      divisions: 18,
                      label: '${(state.overlayOpacity * 100).round()}%',
                      onChanged: (val) => onChanged(state.copyWith(overlayOpacity: val)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
    }
  }

  String _getFrameLabel(CardFrameStyle frame, dynamic s) {
    switch (frame) {
      case CardFrameStyle.none:
        return s.cardFrameNone;
      case CardFrameStyle.line:
        return s.cardFrameSimple;
      case CardFrameStyle.ornate:
        return s.cardFrameOrnate;
      case CardFrameStyle.manuscript:
        return s.cardFrameManuscript;
    }
  }
}
