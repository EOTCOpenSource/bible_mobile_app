import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isLoading = _isLoading || _isGoogleLoading;

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _Header(colors: c),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthField(
                      controller: _emailCtrl,
                      label: 'ኢሜል',
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'ኢሜል ያስፈልጋል';
                        if (!v.contains('@')) return 'ትክክለኛ ኢሜል ያስፈልጋል';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _passwordCtrl,
                      label: 'የይለፍ ቃል',
                      hint: '••••••••',
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
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'የይለፍ ቃል ያስፈልጋል';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                        child: Text(
                          'የይለፍ ቃል ረሳሁ?',
                          style: AppTypography.amharicCaption.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 4),
                    ] else
                      const SizedBox(height: 8),
                    _PrimaryButton(
                      label: 'ግባ',
                      isLoading: _isLoading,
                      onTap: isLoading ? null : _login,
                    ),
                    const SizedBox(height: 20),
                    _Divider(colors: c),
                    const SizedBox(height: 20),
                    _GoogleButton(
                      isLoading: _isGoogleLoading,
                      onTap: isLoading ? null : _googleSignIn,
                    ),
                    const SizedBox(height: 32),
                    _RegisterPrompt(enabled: !isLoading),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: c.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            AppIcons.ethiopianCross,
            style: TextStyle(fontSize: 30, color: c.accent, height: 1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ወደ መጽሐፍ ቅዱስ ግባ',
          style: AppTypography.amharicHeading.copyWith(
            color: c.textOnParchment,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to sync your reading across devices',
          style: AppTypography.englishCaption.copyWith(color: c.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
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
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: c.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: Color(0xFFB71C1C)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB71C1C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.amharicCaption.copyWith(
                color: const Color(0xFFB71C1C),
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
        height: 52,
        decoration: BoxDecoration(
          color: onTap == null ? c.primary.withValues(alpha: 0.5) : c.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.accent,
                ),
              )
            : Text(
                label,
                style: AppTypography.amharicLabel.copyWith(
                  color: c.accent,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

// ── Divider with cross ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Expanded(child: Divider(color: c.borderSubtle, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppIcons.ethiopianCross,
            style: TextStyle(color: c.accentDeep, fontSize: 13, height: 1),
          ),
        ),
        Expanded(child: Divider(color: c.borderSubtle, thickness: 1)),
      ],
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderSubtle, width: 1.2),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  Text(
                    'Google በኩል ግባ',
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textBody,
                      fontWeight: FontWeight.w600,
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
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;

    // Blue arc (top-right)
    canvas.drawArc(rect, -1.57, 3.14, false,
        Paint()..color = const Color(0xFF4285F4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18);

    // Red arc (top-left)
    canvas.drawArc(rect, 1.57, 1.57, false,
        Paint()..color = const Color(0xFFEA4335)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18);

    // Yellow arc (bottom-left)
    canvas.drawArc(rect, 3.14, 0.78, false,
        Paint()..color = const Color(0xFFFBBC05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18);

    // Green arc (bottom-right)
    canvas.drawArc(rect, 3.93, 0.79, false,
        Paint()..color = const Color(0xFF34A853)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18);

    // White horizontal bar for the "G"
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy - size.height * 0.09,
          size.width * 0.92, center.dy + size.height * 0.09),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          'መለያ የለዎትም? ',
          style: AppTypography.amharicCaption.copyWith(color: c.textMuted),
        ),
        GestureDetector(
          onTap: enabled
              ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  )
              : null,
          child: Text(
            'ይመዝገቡ',
            style: AppTypography.amharicCaption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
