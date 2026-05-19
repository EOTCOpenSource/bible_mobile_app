import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email, this.phone});

  final String email;
  final String? phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _otpLength = 6;
  static const _resendSeconds = 60;

  final _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _countdown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _maskedContact {
    final phone = widget.phone;
    if (phone != null && phone.isNotEmpty) {
      if (phone.length >= 7) {
        final visible = phone.substring(phone.length - 3);
        return '${phone.substring(0, phone.length > 4 ? 4 : 1)} ••• ••• $visible';
      }
      return phone;
    }
    final parts = widget.email.split('@');
    final name = parts[0];
    final masked = name.length > 2
        ? '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}'
        : name;
    return '$masked@${parts.length > 1 ? parts[1] : ''}';
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1) {
      if (index < _otpLength - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < _otpLength) {
      setState(() => _errorMessage = 'የ$_otpLength ቁጥር ኮድ ያስፈልጋል');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ref.read(authStateProvider.notifier).verifyOtp(widget.email, otp);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
      _clearOtp();
    } catch (_) {
      setState(() => _errorMessage = 'ግንኙነት አልተሳካም። ድጋሚ ይሞክሩ።');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0 || _isResending) return;
    setState(() { _isResending = true; _errorMessage = null; });
    try {
      await ref.read(authRepositoryProvider).resendOtp(widget.email);
      _clearOtp();
      _startCountdown();
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'ኮድ መላክ አልተሳካም። ድጋሚ ይሞክሩ።');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    FocusScope.of(context).requestFocus(_focusNodes[0]);
    setState(() {});
  }

  String _countdownLabel() {
    final m = (_countdown ~/ 60).toString().padLeft(2, '0');
    final s = (_countdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final otpFilled = _otp.length == _otpLength;

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
                'ኮድዎን ያረጋግጡ',
                style: AppTypography.amharicDisplay.copyWith(
                  color: c.textOnParchment,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTypography.amharicBody.copyWith(
                    color: c.textMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'ወደ '),
                    TextSpan(
                      text: _maskedContact,
                      style: TextStyle(
                          color: c.textOnParchment,
                          fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(
                        text: ' 6 አሃዝ ኮድ ልከናል። አባክዎ ከታች ያስገቡ።'),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              _ShieldIcon(colors: c),
              const SizedBox(height: 36),
              _OtpBoxes(
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onDigitChanged,
                enabled: !_isLoading,
                colors: c,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 24),
              _ResendRow(
                countdown: _countdown,
                isResending: _isResending,
                countdownLabel: _countdownLabel(),
                onResend: _resend,
                colors: c,
              ),
              const SizedBox(height: 28),
              _PrimaryButton(
                label: 'አረጋጥ',
                isLoading: _isLoading,
                onTap: (!otpFilled || _isLoading) ? null : _verify,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: c.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.phone != null && widget.phone!.isNotEmpty
                            ? 'ስልክ ቁጥር ለውጥ'
                            : 'ኢሜል ለውጥ',
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shield icon ───────────────────────────────────────────────────────────────

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.colors});
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
        child: Text(
          AppIcons.ethiopianCross,
          style: TextStyle(fontSize: 34, color: c.accent, height: 1),
        ),
      ),
    );
  }
}

// ── OTP boxes ─────────────────────────────────────────────────────────────────

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.enabled,
    required this.colors,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String, int) onChanged;
  final bool enabled;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (i) {
        final filled = controllers[i].text.isNotEmpty;
        return SizedBox(
          width: 46,
          height: 56,
          child: TextFormField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: AppTypography.amharicHeading.copyWith(
              color: c.textOnParchment,
              fontSize: 20,
            ),
            onChanged: (v) => onChanged(v, i),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: filled ? c.primary.withValues(alpha: 0.06) : c.surface,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: filled ? c.primary : c.borderSubtle,
                  width: filled ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.primary, width: 1.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Resend row ────────────────────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.countdown,
    required this.isResending,
    required this.countdownLabel,
    required this.onResend,
    required this.colors,
  });

  final int countdown;
  final bool isResending;
  final String countdownLabel;
  final VoidCallback onResend;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final canResend = countdown == 0 && !isResending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ኮድ አልደረሰዎትም? ',
          style: AppTypography.amharicCaption.copyWith(
              color: c.textMuted, fontSize: 12),
        ),
        if (countdown > 0)
          Text(
            'ደጎሚ ሊክ ቤ $countdownLabel',
            style: AppTypography.amharicCaption.copyWith(
              color: c.textCaption,
              fontSize: 12,
            ),
          )
        else
          GestureDetector(
            onTap: canResend ? onResend : null,
            child: isResending
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: c.primary),
                  )
                : Text(
                    'ደጎሚ ሊክ',
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
