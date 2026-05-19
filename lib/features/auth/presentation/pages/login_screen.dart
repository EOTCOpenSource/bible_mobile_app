import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authStateProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.isAccountLocked
            ? 'መለያዎ ተቆልፏል። ከ2 ሰዓት በኋላ ይሞክሩ።'
            : e.message;
      });
    } catch (_) {
      setState(() => _errorMessage = 'ግንኙነት አልተሳካም። ድጋሚ ይሞክሩ።');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isGoogleLoading = true; _errorMessage = null; });
    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Google ግባ አልተሳካም። ድጋሚ ይሞክሩ።');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _appleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Apple Sign In — በቅርብ ይመጣል',
          style: AppTypography.amharicCaption.copyWith(color: Colors.white),
        ),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final isLoading = _isLoading || _isGoogleLoading;

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppHeader(s: s),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    _TitleSection(colors: c),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InputField(
                            controller: _emailCtrl,
                            label: 'ኢሜል',
                            hint: 'nehmia@bible.app',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'ኢሜል ያስፈልጋል';
                              if (!v.contains('@')) return 'ትክክለኛ ኢሜል ያስፈልጋል';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _passwordCtrl,
                            label: 'የይለፍ ቃል',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            enabled: !isLoading,
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
                              if (v == null || v.isEmpty) {
                                return 'የይለፍ ቃል ያስፈልጋል';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _RememberForgotRow(
                            rememberMe: _rememberMe,
                            enabled: !isLoading,
                            onRememberChanged: (v) =>
                                setState(() => _rememberMe = v),
                            onForgotTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _ErrorBanner(message: _errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          _PrimaryButton(
                            label: 'ግባ',
                            isLoading: _isLoading,
                            onTap: isLoading ? null : _login,
                          ),
                          const SizedBox(height: 24),
                          _OrDivider(colors: c),
                          const SizedBox(height: 20),
                          _SocialRow(
                            isGoogleLoading: _isGoogleLoading,
                            allDisabled: isLoading,
                            onGoogle: _googleSignIn,
                            onApple: _appleSignIn,
                          ),
                          const SizedBox(height: 28),
                          _RegisterPrompt(enabled: !isLoading),
                          const SizedBox(height: 24),
                          _VerseQuote(colors: c),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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

// ── App header ────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isAmharic = s is AmStrings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              AppIcons.ethiopianCross,
              style: TextStyle(fontSize: 18, color: c.accent, height: 1),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ቅዱስ መጽሐፍ',
                style: AppTypography.amharicLabel.copyWith(
                  color: c.textOnParchment,
                  fontSize: 13,
                ),
              ),
              Text(
                'AMHARIC BIBLE',
                style: AppTypography.englishCaption.copyWith(
                  color: c.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => L10n.switchLanguage(
              context,
              isAmharic ? AppLanguage.english : AppLanguage.amharic,
            ),
            child: Row(
              children: [
                Text(
                  isAmharic ? 'አማርኛ' : 'English',
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: c.textMuted, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Title section ─────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'እንኳን ደህና መጡ',
          style: AppTypography.amharicDisplay.copyWith(
            color: c.textOnParchment,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ቅዱስ ቃልን ንዝምን ለመቀጠል ይግቡ።',
          style: AppTypography.amharicBody.copyWith(
            color: c.textMuted,
            fontSize: 14,
            height: 1.6,
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
          validator: validator,
          style: AppTypography.amharicBody.copyWith(
            color: c.textOnParchment,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.englishCaption.copyWith(
              color: c.textCaption,
              fontSize: 14,
            ),
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

// ── Remember me + Forgot password row ────────────────────────────────────────

class _RememberForgotRow extends StatelessWidget {
  const _RememberForgotRow({
    required this.rememberMe,
    required this.enabled,
    required this.onRememberChanged,
    required this.onForgotTap,
  });

  final bool rememberMe;
  final bool enabled;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        GestureDetector(
          onTap: enabled ? () => onRememberChanged(!rememberMe) : null,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: rememberMe ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: rememberMe ? c.primary : c.borderSubtle,
                    width: 1.5,
                  ),
                ),
                child: rememberMe
                    ? Icon(Icons.check_rounded,
                        color: c.accent, size: 13)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'አስታወስኝ',
                style: AppTypography.amharicCaption.copyWith(
                  color: c.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: enabled ? onForgotTap : null,
          child: Text(
            'የይለፍ ቃል ረሳህ?',
            style: AppTypography.amharicCaption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
              style: AppTypography.amharicCaption.copyWith(
                color: c.primary,
                fontSize: 12,
              ),
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
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.accent,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: c.accent, size: 20),
                ],
              ),
      ),
    );
  }
}

// ── Or divider ────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Expanded(child: Divider(color: c.borderSubtle, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'ወይም ቤዝህ ይግቡ',
            style: AppTypography.amharicCaption.copyWith(
              color: c.textCaption,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(child: Divider(color: c.borderSubtle, thickness: 1)),
      ],
    );
  }
}

// ── Social buttons row ────────────────────────────────────────────────────────

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.isGoogleLoading,
    required this.allDisabled,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isGoogleLoading;
  final bool allDisabled;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            onTap: allDisabled ? null : onGoogle,
            isLoading: isGoogleLoading,
            label: 'Google',
            dark: false,
            icon: _GoogleLogo(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            onTap: allDisabled ? null : onApple,
            isLoading: false,
            label: 'Apple',
            dark: true,
            icon: const Icon(Icons.apple_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
    required this.dark,
    required this.icon,
  });

  final VoidCallback? onTap;
  final bool isLoading;
  final String label;
  final bool dark;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1A1A1A) : c.surface,
          borderRadius: BorderRadius.circular(12),
          border: dark ? null : Border.all(color: c.borderSubtle, width: 1.2),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: dark ? Colors.white : c.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTypography.englishLabel.copyWith(
                      color: dark ? Colors.white : c.textBody,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _GooglePainter();
  }
}

class _GooglePainter extends StatelessWidget {
  const _GooglePainter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.17;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(stroke / 2, stroke / 2,
        w - stroke, h - stroke);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.57, 2.8, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.57 + 0.37, 1.2, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14, 0.74, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.93, 0.83, false, paint);

    final center = Offset(w / 2, h / 2);
    canvas.drawRect(
      Rect.fromLTRB(
          center.dx, center.dy - h * 0.1, w - stroke / 2, center.dy + h * 0.1),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Register prompt ───────────────────────────────────────────────────────────

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'አካውንት የለዎትም? ',
          style: AppTypography.amharicCaption.copyWith(
              color: c.textMuted, fontSize: 12),
        ),
        GestureDetector(
          onTap: enabled
              ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  )
              : null,
          child: Text(
            'ይ​መዝ​ጋቡ',
            style: AppTypography.amharicCaption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bible verse quote ─────────────────────────────────────────────────────────

class _VerseQuote extends StatelessWidget {
  const _VerseQuote({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppIcons.malteseCross,
            style: TextStyle(color: c.accentDeep, fontSize: 12)),
        const SizedBox(width: 8),
        Text(
          'ቃልህ ለምንጊዜም ብርሃን ነው',
          style: AppTypography.amharicCaption.copyWith(
            color: c.textCaption,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        Text(AppIcons.malteseCross,
            style: TextStyle(color: c.accentDeep, fontSize: 12)),
      ],
    );
  }
}
