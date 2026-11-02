import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../books/providers/reading_progress_providers.dart';
import '../pages/streak_screen.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.dateLabel,
    required this.onReadToday,
  });

  final String dateLabel;

  /// Forwarded to [StreakScreen] so its call-to-action can reach the books tab.
  final VoidCallback onReadToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final user = ref.watch(authStateProvider).user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  _greeting(s, user),
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
          StreakPill(onReadToday: onReadToday),
          const SizedBox(width: 10),
          if (user == null)
            _SignInButton(colors: c)
          else
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

// ── Streak pill ────────────────────────────────────────────────────────────────

/// The 🔥 N chip beside the avatar; opens the full streak page.
///
/// This is the whole streak surface on Home now — the old card below the header
/// cost a screenful to say one number.
class StreakPill extends ConsumerWidget {
  const StreakPill({super.key, required this.onReadToday});

  final VoidCallback onReadToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final settings = Settings.of(context);
    final useGeez = settings.useGeezNumbers;
    final count = ref.watch(readingStreakStateProvider).value?.currentStreak ?? 0;

    return Semantics(
      button: true,
      label: s.semanticsStreakCard,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StreakScreen(onReadToday: onReadToday),
            ),
          ),
          child: ExcludeSemantics(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(settings.streakEmoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    useGeez ? toGeez(count) : '$count',
                    style: AppTypography.amharicSubheading.copyWith(
                      color: c.textOnParchment,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              s.loginButton,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.amharicLabel.copyWith(
                color: c.textOnDark,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header avatar, sized to match the streak pill beside it.
///
/// A remote photo goes through three states — loading, loaded, broken — and
/// each falls back to the initials circle rather than to a blank or a raw
/// broken-image glyph, which is what made this look unfinished while the
/// network was slow.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.colors});

  static const double _size = 44;

  final UserProfile user;
  final AppColorScheme colors;

  String get _initial =>
      user.name.trim().isNotEmpty ? user.name.trim().characters.first : '?';

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: user.avatar == null
            ? _InitialsCircle(letter: _initial, colors: c)
            : Image.network(
                user.avatar!,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : _InitialsCircle(letter: _initial, colors: c),
                errorBuilder: (context, error, stack) =>
                    _InitialsCircle(letter: _initial, colors: c),
              ),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.letter, required this.colors});

  final String letter;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      color: c.primary,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.amharicSubheading.copyWith(
          color: c.accent,
          fontSize: 18,
        ),
      ),
    );
  }
}
