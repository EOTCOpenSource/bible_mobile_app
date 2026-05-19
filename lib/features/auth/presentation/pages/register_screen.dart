import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';

// Stub — full implementation in Step 4
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.parchment,
      appBar: AppBar(
        backgroundColor: c.parchment,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textOnParchment, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'ምዝገባ — በቅርብ ይመጣል',
          style: AppTypography.amharicBody.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}
