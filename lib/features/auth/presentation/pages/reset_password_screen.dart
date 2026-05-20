import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password requirement checks ───────────────────────────────────────────

  bool get _hasLength => _passwordCtrl.text.length >= 8;
  bool get _hasUpper => _passwordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _passwordsMatch =>
      _passwordCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  bool get _canSubmit =>
      _tokenCtrl.text.isNotEmpty &&
      _hasLength &&
      _hasUpper &&
      _hasNumber &&
      _passwordsMatch;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _tokenCtrl.text.trim(),
            _passwordCtrl.text,
          );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => route.isFirst,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.of(context).resetSuccessMessage,
              style: AppTypography.amharicCaption
                  .copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = L10n.of(context).authConnectionError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _BackButton(),
              const SizedBox(height: 24),
              Text(
                s.resetTitle,
                style: AppTypography.amharicDisplay.copyWith(
                  color: c.textOnParchment,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.resetSubtitle,
                style: AppTypography.amharicBody.copyWith(
                  color: c.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              _IconBox(colors: c),
              const SizedBox(height: 32),

              // Token field
              _FieldLabel(label: s.resetTokenLabel, colors: c),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _tokenCtrl,
                hint: 'reset-token-from-email',
                prefixIcon: Icons.tag_rounded,
                obscureText: false,
                showSuffix: false,
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // New password
              _FieldLabel(label: s.resetNewPasswordLabel, colors: c),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _passwordCtrl,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                showSuffix: true,
                enabled: !_isLoading,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Confirm password
              _FieldLabel(label: s.resetConfirmLabel, colors: c),
              const SizedBox(height: 6),
              _PasswordField(
                controller: _confirmCtrl,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                showSuffix: true,
                showMatch: _passwordsMatch,
                enabled: !_isLoading,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Requirements checklist
              _RequirementsCard(
                hasLength: _hasLength,
                hasUpper: _hasUpper,
                hasNumber: _hasNumber,
                hasSpecial: _hasSpecial,
                colors: c,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 28),
              _PrimaryButton(
                label: s.resetSaveButton,
                isLoading: _isLoading,
                onTap: (!_canSubmit || _isLoading) ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Requirements card ─────────────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({
    required this.hasLength,
    required this.hasUpper,
    required this.hasNumber,
    required this.hasSpecial,
    required this.colors,
  });

  final bool hasLength;
  final bool hasUpper;
  final bool hasNumber;
  final bool hasSpecial;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).resetRequirementsTitle,
            style: AppTypography.amharicCaption.copyWith(
              color: c.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _Requirement(met: hasLength, label: L10n.of(context).resetReqLength, colors: c),
          const SizedBox(height: 6),
          _Requirement(met: hasUpper, label: L10n.of(context).resetReqUpper, colors: c),
          const SizedBox(height: 6),
          _Requirement(met: hasNumber, label: L10n.of(context).resetReqNumber, colors: c),
          const SizedBox(height: 6),
          _Requirement(met: hasSpecial, label: L10n.of(context).resetReqSpecial, colors: c),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({
    required this.met,
    required this.label,
    required this.colors,
  });

  final bool met;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final color = met ? const Color(0xFF2E7D32) : c.textCaption;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: met ? const Color(0xFF2E7D32).withValues(alpha: 0.12) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: met ? const Color(0xFF2E7D32) : c.borderSubtle,
              width: 1.5,
            ),
          ),
          child: met
              ? const Icon(Icons.check_rounded,
                  color: Color(0xFF2E7D32), size: 11)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Password field ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.obscureText,
    required this.showSuffix,
    required this.enabled,
    this.showMatch = false,
    this.onToggleObscure,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final bool showSuffix;
  final bool showMatch;
  final bool enabled;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget? suffix;
    if (showMatch) {
      suffix = Icon(Icons.check_circle_rounded,
          color: const Color(0xFF2E7D32), size: 20);
    } else if (showSuffix) {
      suffix = IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: c.textCaption,
          size: 20,
        ),
        onPressed: onToggleObscure,
      );
    }

    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      style: AppTypography.amharicBody
          .copyWith(color: c.textOnParchment, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.englishCaption
            .copyWith(color: c.textCaption, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: c.textCaption, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.chevron_left_rounded,
            color: c.textOnParchment, size: 22),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.lock_reset_rounded, color: c.accent, size: 36),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.colors});
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.amharicCaption.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.amharicCaption
                    .copyWith(color: c.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: onTap == null ? c.primary.withValues(alpha: 0.5) : c.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: c.accent),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AppTypography.amharicLabel
                          .copyWith(color: c.accent, fontSize: 16)),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: c.accent, size: 20),
                ],
              ),
      ),
    );
  }
}
