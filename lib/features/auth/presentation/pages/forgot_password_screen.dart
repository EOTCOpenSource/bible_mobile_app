import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _useEmail = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = L10n.of(context);
    if (!_useEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.forgotPhoneComingSoon,
            style: AppTypography.amharicCaption.copyWith(color: Colors.white),
          ),
          backgroundColor: context.colors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = s.authEmailInvalid);
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email),
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
                s.forgotTitle,
                style: AppTypography.amharicDisplay.copyWith(
                  color: c.textOnParchment,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.forgotSubtitle,
                style: AppTypography.amharicBody.copyWith(
                  color: c.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              _IconBox(icon: Icons.key_rounded, colors: c),
              const SizedBox(height: 32),
              _TabSwitcher(
                useEmail: _useEmail,
                onChanged: (v) => setState(() {
                  _useEmail = v;
                  _errorMessage = null;
                }),
                colors: c,
              ),
              const SizedBox(height: 20),
              if (_useEmail) ...[
                _FieldLabel(
                  label: s.forgotEmailLabel,
                  active: true,
                  colors: c,
                ),
                const SizedBox(height: 6),
                _InputField(
                  controller: _emailCtrl,
                  hint: 'nehmia@bible.app',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 8),
                Text(
                  s.forgotEmailHelper,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textCaption,
                    fontSize: 11,
                  ),
                ),
              ] else ...[
                _FieldLabel(
                  label: s.forgotPhoneLabel,
                  active: true,
                  colors: c,
                ),
                const SizedBox(height: 6),
                _InputField(
                  controller: _phoneCtrl,
                  hint: '+251 911 234 567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 8),
                Text(
                  s.forgotPhoneHelper,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textCaption,
                    fontSize: 11,
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 32),
              _PrimaryButton(
                label: s.forgotSendButton,
                isLoading: _isLoading,
                onTap: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.forgotRememberPassword,
                    style: AppTypography.amharicCaption.copyWith(
                        color: c.textMuted, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                    child: Text(
                      s.loginButton,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab switcher ──────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.useEmail,
    required this.onChanged,
    required this.colors,
  });

  final bool useEmail;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      decoration: BoxDecoration(
        color: c.parchmentDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            icon: Icons.email_outlined,
            label: L10n.of(context).authEmail,
            active: useEmail,
            onTap: () => onChanged(true),
            colors: c,
          ),
          _Tab(
            icon: Icons.phone_outlined,
            label: L10n.of(context).forgotTabPhone,
            active: !useEmail,
            onTap: () => onChanged(false),
            colors: c,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? c.primary : c.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.amharicCaption.copyWith(
                  color: active ? c.primary : c.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.active,
    required this.colors,
  });
  final String label;
  final bool active;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Text(
      label,
      style: AppTypography.amharicCaption.copyWith(
        color: active ? c.primary : c.textMuted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
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
  const _IconBox({required this.icon, required this.colors});
  final IconData icon;
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
        child: Icon(icon, color: c.accent, size: 36),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: AppTypography.amharicBody
          .copyWith(color: c.textOnParchment, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.englishCaption
            .copyWith(color: c.textCaption, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: c.textCaption, size: 18),
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
