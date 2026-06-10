import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:kenat/kenat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../books/data/models/book.dart';
import 'pickers/background_picker.dart';
import 'pickers/ratio_picker.dart';
import 'pickers/reference_picker.dart';
import 'pickers/text_picker.dart';
import 'verse_card_models.dart';
import 'verse_card_renderer.dart';
import 'verse_card_state.dart';

class VerseCardSheet extends StatefulWidget {
  final List<Verse> verses;
  final Book book;
  final int chapterNumber;

  const VerseCardSheet({
    super.key,
    required this.verses,
    required this.book,
    required this.chapterNumber,
  });

  @override
  State<VerseCardSheet> createState() => _VerseCardSheetState();
}

class _VerseCardSheetState extends State<VerseCardSheet> with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  late TabController _tabController;
  late VerseCardState _state;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = Settings.of(context);
      _state = VerseCardState.initial(
        initialBgType: settings.cardBgType,
        initialSolidColorIndex: settings.cardSolidColorIndex,
        initialGradientIndex: settings.cardGradientIndex,
        initialFrameStyleIndex: settings.cardFrameStyleIndex,
        initialFontIndex: settings.cardFontIndex,
        initialAspectRatioIndex: settings.cardAspectRatio,
        defaultGeez: settings.useGeezNumbers,
        defaultAmharic: L10n.of(context) is AmStrings,
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateState(VerseCardState newState) {
    setState(() {
      _state = newState;
    });

    // Save preferences dynamically to AppSettings
    final currentSettings = Settings.of(context);
    Settings.update(
      context,
      currentSettings.copyWith(
        cardBgType: newState.bgType.index,
        cardSolidColorIndex: newState.solidColorIndex,
        cardGradientIndex: newState.gradientIndex,
        cardFrameStyleIndex: newState.frameStyle.index,
        cardFontIndex: newState.fontIndex,
        cardAspectRatio: newState.aspectRatio.index,
      ),
    );
  }

  // Smart text color suggestion on background change
  void _updateBackgroundState(VerseCardState newState) {
    CardTextColorMode suggestedTextColor = _state.textColorMode;

    if (newState.bgType == CardBgType.solid) {
      final color = VerseCardPresets.solidColors[newState.solidColorIndex];
      suggestedTextColor = color.computeLuminance() > 0.45
          ? CardTextColorMode.dark
          : CardTextColorMode.light;
    } else if (newState.bgType == CardBgType.gradient) {
      final colors = VerseCardPresets.gradientPresets[newState.gradientIndex];
      final avgLuminance = colors.map((c) => c.computeLuminance()).reduce((a, b) => a + b) / colors.length;
      suggestedTextColor = avgLuminance > 0.45
          ? CardTextColorMode.dark
          : CardTextColorMode.light;
    }

    _updateState(newState.copyWith(textColorMode: suggestedTextColor));
  }

  String get _joinedVerseText => widget.verses.map((v) => v.text.trim()).join(' ');

  String get _formattedReference {
    final start = widget.verses.first.verseNumber;
    final end = widget.verses.last.verseNumber;
    final isRange = start != end;
    final bookName = _state.useAmharicBookName ? widget.book.bookNameAm : widget.book.bookNameEn;
    final chapterStr = _state.useGeezRef ? toGeez(widget.chapterNumber) : '${widget.chapterNumber}';
    final startStr = _state.useGeezRef ? toGeez(start) : '$start';
    final endStr = _state.useGeezRef ? toGeez(end) : '$end';

    return isRange
        ? '$bookName $chapterStr:$startStr-$endStr'
        : '$bookName $chapterStr:$startStr';
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final s = L10n.of(context);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final result = await ImageGallerySaverPlus.saveImage(
          imageBytes,
          quality: 100,
          name: "verse_card_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (!mounted) return;
        final isSuccess = result != null && (result['isSuccess'] == true || result == true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? s.cardSaved : s.cardSaveFailed),
            backgroundColor: isSuccess ? AppColors.accentDeep : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.cardSaveFailed}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareAsText() async {
    final text = '$_joinedVerseText\n\n— $_formattedReference';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final s = L10n.of(context);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/verse_share_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(imageBytes);

        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin = box != null
            ? Rect.fromLTWH(0, 0, box.size.width, box.size.height / 2)
            : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.cardSaveFailed}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final verseText = _joinedVerseText;
    final reference = _formattedReference;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  s.cardSheetTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main layout containing Preview + Options Scroll Area
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card Preview Panel with bounded size
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.38,
                      ),
                      child: Center(
                        child: Screenshot(
                          controller: _screenshotController,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              width: 270, // Fixed preview width for UI layout
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: VerseCardRenderer(
                                state: _state,
                                verseText: verseText,
                                reference: reference,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Option Categories (Tab bar style)
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(icon: const Icon(Icons.wallpaper, size: 20), text: s.cardTabBackground),
                      Tab(icon: const Icon(Icons.title, size: 20), text: s.cardTabText),
                      Tab(icon: const Icon(Icons.menu_book, size: 20), text: s.cardTabReference),
                      Tab(icon: const Icon(Icons.aspect_ratio, size: 20), text: s.cardTabRatio),
                    ],
                  ),

                  // Tab content panel
                  Container(
                    height: 180,
                    color: isDark ? const Color(0xFF151515) : Colors.grey[50],
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BackgroundPicker(state: _state, onChanged: _updateBackgroundState),
                        TextPicker(state: _state, onChanged: _updateState),
                        ReferencePicker(state: _state, onChanged: _updateState),
                        RatioPicker(state: _state, onChanged: _updateState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Bottom Buttons (Save & Share)
          Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
            ),
            child: Row(
              children: [
                // Save button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || _isSharing) ? null : _saveToGallery,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(s.cardSaveToGallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Share image button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isSaving || _isSharing) ? null : _shareCard,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(s.cardShare),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: theme.colorScheme.primary),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Share as text — compact icon button
                Tooltip(
                  message: s.cardShareAsText,
                  child: OutlinedButton(
                    onPressed: (_isSaving || _isSharing) ? null : _shareAsText,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: theme.colorScheme.primary),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: const Icon(Icons.text_fields_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
