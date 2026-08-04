import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/web_reader/local_server_service.dart';
import '../../../../core/web_reader/web_reader_providers.dart';

/// The Local Web Reader control, in the Me screen's Device section.
///
/// Off it is one button. On it is the address to type on the laptop, a copy
/// button and a QR code — the three ways a URL gets from a phone to another
/// screen in the room.
class WebReaderCard extends ConsumerWidget {
  const WebReaderCard({super.key});

  /// What to tell the user about a failed start, or null when there is nothing
  /// to say — a cancelled start is the app being backgrounded, which the user
  /// did on purpose.
  static String? errorMessage(AppStrings s, LocalServerError? error) =>
      switch (error) {
        null || LocalServerError.cancelled => null,
        LocalServerError.noNetwork => s.webReaderNoNetwork,
        LocalServerError.noFreePort => s.webReaderNoPort,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = L10n.of(context);
    final state = ref.watch(webReaderProvider);
    final notifier = ref.read(webReaderProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.webReaderTitle,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.textOnParchment,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isRunning ? s.webReaderRunningHint : s.webReaderHint,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: state.isBusy
                    ? s.webReaderStarting
                    : state.isRunning
                        ? s.webReaderStop
                        : s.webReaderStart,
                busy: state.isBusy,
                running: state.isRunning,
                onTap: state.isBusy
                    ? null
                    : state.isRunning
                        ? notifier.stop
                        : notifier.start,
              ),
            ],
          ),
          if (errorMessage(s, state.error) case final message?) ...[
            const SizedBox(height: 12),
            _ErrorNote(message: message),
          ],
          if (state.url != null) ...[
            const SizedBox(height: 14),
            _AddressRow(url: state.url!, interfaceName: state.interfaceName),
            const SizedBox(height: 14),
            _QrThumb(url: state.url!),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.busy,
    required this.running,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final bool running;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Stopping is the destructive-ish action, so it reads as an outline while
    // starting reads as the filled primary — the same weighting the rest of
    // the app gives a call to action.
    final filled = !running;
    return Material(
      color: filled ? c.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: c.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? c.accent : c.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.amharicLabel.copyWith(
                  color: filled ? c.accent : c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.url, this.interfaceName});

  final String url;
  final String? interfaceName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.webReaderCopied)),
      );
    }

    return InkWell(
      onTap: copy,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surfaceDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    url,
                    style: AppTypography.englishBody.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                    maxLines: 1,
                  ),
                  // The interface is a technical identifier, the same in every
                  // language, so it needs no translation — and it is the one
                  // thing that explains an address the user did not expect.
                  if (interfaceName != null && interfaceName!.isNotEmpty)
                    Text(
                      interfaceName!,
                      style: AppTypography.englishCaption.copyWith(
                        color: c.textCaption,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.copy_rounded, size: 18, color: c.textMuted),
            const SizedBox(width: 4),
            Text(
              s.webReaderCopy,
              style: AppTypography.amharicCaption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrThumb extends StatelessWidget {
  const _QrThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);

    return Row(
      children: [
        InkWell(
          onTap: () => showDialog<void>(
            context: context,
            barrierColor: c.scrim,
            builder: (_) => _QrDialog(url: url),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // The QR itself is drawn dark-on-white in both themes: a scanner
              // needs the contrast, and inverting it stops many of them
              // reading at all.
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderSubtle),
            ),
            child: QrImageView(
              data: url,
              size: 96,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textOnParchment,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            s.webReaderScanHint,
            style: AppTypography.amharicCaption.copyWith(color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

class _QrDialog extends StatelessWidget {
  const _QrDialog({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    // Big enough for a laptop webcam across a desk, but never wider than the
    // phone it is being held up from.
    final side = MediaQuery.sizeOf(context).width * .72;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.webReaderQrTitle,
              style: AppTypography.amharicSubheading.copyWith(
                color: c.textOnParchment,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: url,
                size: side,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textOnParchment,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              url,
              style: AppTypography.englishBody.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.webReaderClose,
                style: AppTypography.amharicLabel.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, size: 17, color: c.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.amharicCaption.copyWith(color: c.primary),
            ),
          ),
        ],
      ),
    );
  }
}
