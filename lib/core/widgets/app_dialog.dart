import 'package:flutter/material.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_typography.dart';

/// The app's one modal look, taken from the Markdown export dialog.
///
/// Every modal — dialog or bottom sheet — is built from the pieces here so the
/// design lives in one place instead of being re-typed at each call site. The
/// shape is: a tinted icon tile, an Amharic title with a spaced Latin caption
/// under it, body content, then a muted text button beside a filled primary
/// button.
///
/// Use [AppDialog] for centred confirmations and [AppSheet] for anything that
/// needs the extra height of a bottom sheet. They share [AppDialogHeader] and
/// [AppDialogActions], so the two read as the same surface.

// ── Metrics ──────────────────────────────────────────────────────────────────

/// The corner radius of a modal surface. Bottom sheets round only the top.
const double kAppDialogRadius = 20;

/// The corner radius of the pieces inside one — icon tile, callout, buttons.
const double kAppDialogInnerRadius = 12;

// ── Header ───────────────────────────────────────────────────────────────────

/// The icon tile, title and Latin caption shared by every modal.
///
/// [caption] is the small letter-spaced line under the title (`'MARKDOWN'`,
/// `'COLLECTIONS'`). It is deliberately Latin and uppercase — it labels the
/// surface without competing with the Amharic title above it.
class AppDialogHeader extends StatelessWidget {
  const AppDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String? caption;

  /// Shows a trailing close button. Bottom sheets want one; dialogs that
  /// already have a cancel action in [AppDialogActions] do not.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(kAppDialogInnerRadius),
          ),
          child: Icon(icon, size: 20, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.amharicLabel.copyWith(
                  color: c.textOnParchment,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: AppTypography.englishLabel.copyWith(
                    color: c.textCaption,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: c.textMuted),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
      ],
    );
  }
}

// ── Body text ────────────────────────────────────────────────────────────────

/// Body copy at the modal's standard size and colour.
class AppDialogBody extends StatelessWidget {
  const AppDialogBody(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text,
      style: AppTypography.amharicBody.copyWith(
        color: c.textMuted,
        fontSize: 14,
        height: 1.55,
      ),
    );
  }
}

// ── Callout ──────────────────────────────────────────────────────────────────

/// The accent-tinted box for the one thing the user is actually being asked to
/// accept — a caveat, a warning, a consequence. Kept out of the body text so it
/// does not read as an aside.
class AppDialogCallout extends StatelessWidget {
  const AppDialogCallout({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kAppDialogInnerRadius),
        border: Border.all(color: c.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: c.accentDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.amharicBody.copyWith(
                color: c.accentDeep,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actions ──────────────────────────────────────────────────────────────────

/// The muted cancel / filled confirm pair.
///
/// [destructive] swaps the confirm button to the error colour for deletions,
/// which is the only variation the app needs.
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    this.cancelLabel,
    this.onCancel,
    required this.confirmLabel,
    required this.onConfirm,
    this.destructive = false,
    this.fullWidth = false,
  });

  final String? cancelLabel;
  final VoidCallback? onCancel;
  final String confirmLabel;

  /// A null [onConfirm] disables the button — used while work is in flight.
  final VoidCallback? onConfirm;
  final bool destructive;

  /// Stretches the confirm button across the modal. Bottom sheets that have no
  /// cancel action use this so the button does not float in the corner.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final confirmColor =
        destructive ? Theme.of(context).colorScheme.error : c.primary;

    final confirm = FilledButton(
      onPressed: onConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: confirmColor,
        foregroundColor: c.textOnDark,
        padding: EdgeInsets.symmetric(
          horizontal: fullWidth ? 16 : 22,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kAppDialogInnerRadius),
        ),
      ),
      child: Text(
        confirmLabel,
        style: AppTypography.amharicLabel.copyWith(
          color: c.textOnDark,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: confirm);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (cancelLabel != null)
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              cancelLabel!,
              style: AppTypography.amharicLabel.copyWith(
                color: c.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        confirm,
      ],
    );
  }
}

// ── Dialog shell ─────────────────────────────────────────────────────────────

/// A centred modal in the app's design.
///
/// Pass [children] for the body; the header and actions are assembled from the
/// named arguments so no call site re-specifies padding or shape.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    required this.children,
    this.actions,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final List<Widget> children;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AlertDialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kAppDialogRadius),
        side: BorderSide(color: c.borderSubtle),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: AppDialogHeader(icon: icon, title: title, caption: caption),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
      actions: actions == null ? null : [actions!],
    );
  }
}

// ── Sheet shell ──────────────────────────────────────────────────────────────

/// A bottom sheet wearing the same design as [AppDialog].
///
/// Keeps the grab handle — it is the affordance that says "drag me" — but
/// otherwise matches the dialog's surface, header and actions.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    required this.children,
    this.actions,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final List<Widget> children;
  final Widget? actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kAppDialogRadius),
          ),
          border: Border(top: BorderSide(color: c.borderSubtle)),
        ),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: c.textMuted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AppDialogHeader(
                    icon: icon,
                    title: title,
                    caption: caption,
                    onClose: onClose,
                  ),
                  const SizedBox(height: 14),
                  ...children,
                  if (actions != null) ...[
                    const SizedBox(height: 16),
                    actions!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
