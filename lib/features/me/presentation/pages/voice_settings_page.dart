import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/audio/addis_tts_client.dart';
import '../../../../core/audio/addis_voice.dart';
import '../../../../core/audio/tts_providers.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/reader/constants.dart';

/// Where the user sets up audio reading: their own Addis AI key, then which
/// voice reads to them.
///
/// The catalog is fetched live rather than hardcoded — Addis AI adds and
/// retires voices, and listing them needs the key, so the two live on one page
/// in that order.
class VoiceSettingsPage extends ConsumerStatefulWidget {
  const VoiceSettingsPage({super.key, this.language = 'am'});

  /// `am` (Amharic) or `om` (Afaan Oromo).
  final String language;

  @override
  ConsumerState<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends ConsumerState<VoiceSettingsPage> {
  final _keyController = TextEditingController();
  final _previewPlayer = AudioPlayer();

  /// Voice id whose sample is loading or playing, for the per-row spinner.
  String? _previewingId;

  /// True while the key field is showing, even if a key is already saved
  /// (the "change key" path).
  bool _editingKey = false;
  bool _savingKey = false;

  @override
  void initState() {
    super.initState();
    _previewPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _previewingId = null);
      }
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _saveKey() async {
    final entered = _keyController.text.trim();
    if (entered.isEmpty) return;

    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingKey = true);

    await ref.read(ttsSettingsStoreProvider).saveApiKey(entered);
    ref.invalidate(addisApiKeyProvider);
    ref.invalidate(voiceCatalogProvider);

    if (!mounted) return;
    setState(() {
      _savingKey = false;
      _editingKey = false;
    });
    _keyController.clear();
    messenger.showSnackBar(SnackBar(content: Text(s.voiceKeySaved)));
  }

  Future<void> _removeKey() async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await _stopPreview();
    await ref.read(ttsSettingsStoreProvider).clearApiKey();
    ref.invalidate(addisApiKeyProvider);
    ref.invalidate(voiceCatalogProvider);

    if (!mounted) return;
    setState(() => _editingKey = false);
    messenger.showSnackBar(SnackBar(content: Text(s.voiceKeyRemoved)));
  }

  Future<void> _copySignupLink() async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: kAddisAiSignupUrl));
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s.voiceKeyLinkCopied)));
  }

  Future<void> _stopPreview() async {
    await _previewPlayer.stop();
    if (mounted) setState(() => _previewingId = null);
  }

  /// Plays a voice's sample clip. Samples come straight from the catalog, so
  /// this costs the user nothing — no generation is billed.
  Future<void> _preview(AddisVoice voice) async {
    if (voice.previewUrl == null) return;
    if (_previewingId == voice.id) {
      await _stopPreview();
      return;
    }

    setState(() => _previewingId = voice.id);
    try {
      await _previewPlayer.stop();
      await _previewPlayer.setUrl(voice.previewUrl!);
      await _previewPlayer.play();
    } on Object {
      if (!mounted) return;
      setState(() => _previewingId = null);
    }
  }

  Future<void> _select(AddisVoice voice) async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(ttsSettingsStoreProvider).saveVoiceId(voice.id);
    ref.invalidate(selectedVoiceIdProvider);

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(s.voiceSelectedToast(voice.name))),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isDark = settings.isDarkReader;

    final bgColor = isDark ? readerDarkBg : AppColors.parchment;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;

    final apiKey = ref.watch(addisApiKeyProvider);
    final hasKey = apiKey.valueOrNull != null;

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
          s.voiceSettingsTitle,
          style: AppTypography.amharicSubheading.copyWith(color: textColor),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _SectionLabel(label: s.voiceSectionKey, isDark: isDark),
          const SizedBox(height: 8),
          _keyCard(s, isDark, hasKey),
          if (hasKey) ...[
            const SizedBox(height: 28),
            _SectionLabel(label: s.voiceSectionVoices, isDark: isDark),
            const SizedBox(height: 8),
            _voiceList(s, isDark),
          ],
        ],
      ),
    );
  }

  Widget _keyCard(AppStrings s, bool isDark, bool hasKey) {
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    final showField = !hasKey || _editingKey;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showField) ...[
            Text(
              s.voiceKeyIntro,
              style: AppTypography.amharicCaption.copyWith(
                color: mutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // No url_launcher in this project, so the signup URL is copied
            // rather than opened.
            OutlinedButton.icon(
              onPressed: _copySignupLink,
              icon: Icon(Icons.open_in_new_rounded, size: 18, color: accentColor),
              label: Text(
                '${s.voiceKeyGetOne} — $kAddisAiSignupUrl',
                style: AppTypography.amharicCaption.copyWith(color: accentColor),
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: s.voiceKeyFieldHint,
                hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                filled: true,
                fillColor: isDark ? Colors.white10 : AppColors.parchment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onSubmitted: (_) => _saveKey(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _savingKey ? null : _saveKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _savingKey
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.voiceKeySave,
                            style: AppTypography.amharicCaption
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
                if (hasKey) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => setState(() => _editingKey = false),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                      style:
                          AppTypography.amharicCaption.copyWith(color: mutedColor),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 20, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.voiceKeySaved,
                    style:
                        AppTypography.amharicBody.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _editingKey = true),
                  child: Text(
                    s.voiceKeyChange,
                    style:
                        AppTypography.amharicCaption.copyWith(color: accentColor),
                  ),
                ),
                TextButton(
                  onPressed: _removeKey,
                  child: Text(
                    s.voiceKeyRemove,
                    style: AppTypography.amharicCaption
                        .copyWith(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _voiceList(AppStrings s, bool isDark) {
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    final catalog = ref.watch(voiceCatalogProvider(widget.language));
    final selectedId = ref.watch(selectedVoiceIdProvider).valueOrNull;
    final effective = ref.watch(effectiveVoiceProvider(widget.language));

    return catalog.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: accentColor, strokeWidth: 2.5),
        ),
      ),
      error: (err, _) {
        final isAuth = err is AddisTtsException && err.isAuthFailure;
        return _MessageBlock(
          message: isAuth ? s.voiceKeyRejected : s.voiceLoadFailed,
          actionLabel: s.voiceRetry,
          onAction: () => ref.invalidate(voiceCatalogProvider),
          isDark: isDark,
        );
      },
      data: (voices) {
        if (voices.isEmpty) {
          return _MessageBlock(
            message: s.voiceListEmpty,
            actionLabel: s.voiceRetry,
            onAction: () => ref.invalidate(voiceCatalogProvider),
            isDark: isDark,
          );
        }

        // Nothing saved yet → highlight the voice that would actually be used,
        // so the list never looks like no choice is in effect.
        final highlightId = selectedId ?? effective.valueOrNull?.id;

        return Column(
          children: [
            for (final voice in voices) ...[
              _VoiceTile(
                voice: voice,
                isSelected: voice.id == highlightId,
                isPreviewing: _previewingId == voice.id,
                isDark: isDark,
                s: s,
                onSelect: () => _select(voice),
                onPreview: () => _preview(voice),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            Text(
              '${voices.length} · ${s.voiceSectionVoices}',
              style: AppTypography.amharicCaption.copyWith(color: mutedColor),
            ),
          ],
        );
      },
    );
  }
}

// ── widgets ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTypography.amharicCaption.copyWith(
          color: isDark ? readerDarkMuted : AppColors.textMuted,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.voice,
    required this.isSelected,
    required this.isPreviewing,
    required this.isDark,
    required this.s,
    required this.onSelect,
    required this.onPreview,
  });

  final AddisVoice voice;
  final bool isSelected;
  final bool isPreviewing;
  final bool isDark;
  final AppStrings s;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    final genderLabel = voice.isMale
        ? s.voiceGenderMale
        : voice.isFemale
            ? s.voiceGenderFemale
            : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.6)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06)),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Preview — plays the catalog sample, never a billed generation.
              if (voice.previewUrl != null)
                IconButton(
                  onPressed: onPreview,
                  visualDensity: VisualDensity.compact,
                  icon: isPreviewing
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: accentColor,
                          ),
                        )
                      : Icon(Icons.play_circle_outline_rounded,
                          size: 26, color: accentColor),
                  tooltip: s.voicePreview,
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            voice.name.isEmpty ? voice.id : voice.name,
                            style: AppTypography.amharicBody.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (voice.isDefault) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: s.voiceDefaultBadge,
                            color: mutedColor,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                    if (voice.descriptor.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        voice.descriptor,
                        style: AppTypography.amharicCaption
                            .copyWith(color: mutedColor, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (genderLabel.isNotEmpty || voice.style.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (genderLabel.isNotEmpty)
                            _Chip(
                              label: genderLabel,
                              color: accentColor,
                              isDark: isDark,
                            ),
                          if (voice.style.isNotEmpty)
                            _Chip(
                              label: voice.style,
                              color: mutedColor,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? accentColor : mutedColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.amharicCaption.copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.isDark,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.amharicCaption
                .copyWith(color: mutedColor, height: 1.5),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: AppTypography.amharicCaption.copyWith(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
