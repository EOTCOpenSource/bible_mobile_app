import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  int _evalStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  String _strengthLabel(int s, AppStrings strings) {
    switch (s) {
      case 1: return strings.passwordWeak;
      case 2: return strings.passwordFair;
      case 3: return strings.passwordGood;
      case 4: return strings.passwordStrong;
      default: return '';
    }
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFFFB8C00);
      case 3: return const Color(0xFF7CB342);
      case 4: return const Color(0xFF2E7D32);
      default: return Colors.transparent;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _errorMessage = L10n.of(context).registerAcceptTerms);
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authStateProvider.notifier).register(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(email: _emailCtrl.text.trim()),
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
    final s = L10n.of(context);
    final c = context.colors;

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
                s.registerTitle,
                style: AppTypography.amharicDisplay.copyWith(
                  color: c.textOnParchment,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.registerSubtitle,
                style: AppTypography.amharicBody.copyWith(
                  color: c.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              _StepProgress(currentStep: 1, totalSteps: 2, colors: c),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InputField(
                      controller: _nameCtrl,
                      label: s.registerFullName,
                      hint: 'ነህምያ ተስፋዬ',
                      prefixIcon: Icons.person_outline_rounded,
                      enabled: !_isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.registerFullNameRequired;
                        if (v.trim().length < 2) return s.registerFullNameTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _emailCtrl,
                      label: s.authEmail,
                      hint: 'nehmia@bible.app',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.authEmailRequired;
                        if (!v.contains('@')) return s.authEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _passwordCtrl,
                      label: s.authPassword,
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      onChanged: (v) =>
                          setState(() => _passwordStrength = _evalStrength(v)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: c.textCaption,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s.authPasswordRequired;
                        if (v.length < 8) return s.registerPasswordTooShort;
                        return null;
                      },
                    ),
                    if (_passwordStrength > 0) ...[
                      const SizedBox(height: 8),
                      _PasswordStrengthBar(
                        strength: _passwordStrength,
                        label: _strengthLabel(_passwordStrength, s),
                        color: _strengthColor(_passwordStrength),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _TermsRow(
                      accepted: _acceptedTerms,
                      enabled: !_isLoading,
                      onChanged: (v) {
                        setState(() {
                          _acceptedTerms = v;
                          if (v) _errorMessage = null;
                        });
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      label: s.registerButton,
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _register,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.registerHaveAccount,
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
                            s.registerLoginLink,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

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

// ── Step progress bar ─────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.colors,
  });

  final int currentStep;
  final int totalSteps;
  final AppColorScheme colors;

  static const _geez = ['፩', '፪', '፫', '፬', '፭', '፮'];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(totalSteps, (i) {
              final active = i < currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? c.primary : c.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_geez[currentStep - 1]}/${_geez[totalSteps - 1]}',
          style: AppTypography.amharicCaption.copyWith(
            color: c.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: c.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator,
          style: AppTypography.amharicBody.copyWith(
            color: c.textOnParchment,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.englishCaption
                .copyWith(color: c.textCaption, fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: c.textCaption, size: 18),
            suffixIcon: suffixIcon,
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
              borderSide: BorderSide(color: c.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.primary.withValues(alpha: 0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Password strength bar ─────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({
    required this.strength,
    required this.label,
    required this.color,
  });

  final int strength;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < strength ? color : c.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Terms row ─────────────────────────────────────────────────────────────────

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.accepted,
    required this.enabled,
    required this.onChanged,
  });

  final bool accepted;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? () => onChanged(!accepted) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: accepted ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: accepted ? c.primary : c.borderSubtle,
                width: 1.5,
              ),
            ),
            child: accepted
                ? Icon(Icons.check_rounded, color: c.accent, size: 13)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L10n.of(context).registerTermsText,
              style: AppTypography.amharicCaption.copyWith(
                color: c.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

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
            child: Text(
              message,
              style: AppTypography.amharicCaption
                  .copyWith(color: c.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────

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
                  Text(
                    label,
                    style: AppTypography.amharicLabel
                        .copyWith(color: c.accent, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: c.accent, size: 20),
                ],
              ),
      ),
    );
  }
}
