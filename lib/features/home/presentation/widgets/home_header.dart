import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final user = ref.watch(authStateProvider).user;

    final greeting = _greeting(s, user);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  greeting,
                  style: AppTypography.amharicHeading.copyWith(
                    color: c.textOnParchment,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(user: user, colors: c),
        ],
      ),
    );
  }

  static String _greeting(AppStrings s, UserProfile? user) {
    if (user == null) return s.welcomeGreeting;
    final firstName = user.name.split(' ').first;
    return s is AmStrings ? 'ሰላም, $firstName' : 'Hello, $firstName';
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.colors});

  final UserProfile? user;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;

    // Google / social login — show profile picture
    if (user?.avatar != null) {
      return ClipOval(
        child: SizedBox(
          width: 50,
          height: 50,
          child: Image.network(
            user!.avatar!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _InitialsCircle(
              letter: _initial(user!.name),
              colors: c,
            ),
          ),
        ),
      );
    }

    // Email/password login — first letter of name
    final letter = user != null ? _initial(user!.name) : 'ን';
    return _InitialsCircle(letter: letter, colors: c);
  }

  static String _initial(String name) =>
      name.isNotEmpty ? name.characters.first : '?';
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.letter, required this.colors});

  final String letter;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: c.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.amharicSubheading.copyWith(
          color: c.textOnDark,
          fontSize: 20,
        ),
      ),
    );
  }
}
