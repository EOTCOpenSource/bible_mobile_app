import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import 'reading_settings_page.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  bool _dailyVerse = true;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isAmharic = s is AmStrings;
    final authState = ref.watch(authStateProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _MeAppBar(s: s)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _ProfileCard(s: s, user: authState.user),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Reading ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionReading,
              enLabel: 'READING',
              rows: [
                _ArrowRow(label: s.settingTranslation, value: s.settingTranslationValue),
                _ArrowRow(
                  label: s.settingReadingPrefs,
                  hint: s.settingReadingPrefsHint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadingSettingsPage()),
                  ),
                ),
                _ToggleRow(
                  label: s.settingNightMode,
                  hint: s.settingNightModeHint,
                  value: settings.isDarkReader,
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(isDarkReader: v),
                  ),
                ),
                _ActionRow(
                  label: s.settingAudio,
                  actionLabel: s.settingAudioAction,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Language ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionLanguage,
              enLabel: 'LANGUAGE',
              rows: [
                _LanguageRow(s: s, isAmharic: isAmharic),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Numbers ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionNumbers,
              enLabel: 'NUMBERS',
              rows: [
                _ToggleRow(
                  label: s.settingGeezNums,
                  hint: s.settingGeezNumsHint,
                  value: settings.useGeezNumbers,
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(useGeezNumbers: v),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Reminders ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionReminders,
              enLabel: 'REMINDERS',
              rows: [
                _ToggleRow(
                  label: s.settingDailyVerse,
                  hint: s.settingDailyVerseHint,
                  value: _dailyVerse,
                  onChanged: (v) => setState(() => _dailyVerse = v),
                ),
                _ArrowRow(label: s.settingReadingTime, hint: s.settingReadingTimeHint),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _MeAppBar extends StatelessWidget {
  const _MeAppBar({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            s.meTitle,
            style: AppTypography.amharicHeading.copyWith(
              color: c.textOnParchment,
            ),
          ),
          const Spacer(),
          Text(
            'Settings',
            style: AppTypography.englishLabel.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.s, required this.user});
  final AppStrings s;
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (user == null) return _GuestCard(s: s, colors: c);
    final initial = user!.name.isNotEmpty ? user!.name.characters.first : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user!.avatar != null)
                ClipOval(
                  child: Image.network(
                    user!.avatar!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => _InitialsCircle(
                      initial: initial,
                      accent: c.accent,
                      primary: c.primary,
                    ),
                  ),
                )
              else
                _InitialsCircle(
                  initial: initial,
                  accent: c.accent,
                  primary: c.primary,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.name,
                      style: const TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user!.email,
                      style: AppTypography.amharicCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.meProfileEditBadge,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initial,
    required this.accent,
    required this.primary,
  });

  final String initial;
  final Color accent;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppTypography.shiromeda,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.s, required this.colors});
  final AppStrings s;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: c.accent.withValues(alpha: 0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_outline_rounded,
                    color: c.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ግባ ወይም ተመዝገብ',
                      style: const TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ማስታወሻዎትን ወደ ደመና ያስቀምጡ',
                      style: AppTypography.amharicCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings section ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.amLabel,
    required this.enLabel,
    required this.rows,
  });

  final String amLabel;
  final String enLabel;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                amLabel,
                style: AppTypography.amharicLabel.copyWith(color: c.textMuted),
              ),
              Text(
                ' · ',
                style: AppTypography.englishLabel.copyWith(color: c.textMuted),
              ),
              Text(
                enLabel,
                style: AppTypography.englishLabel.copyWith(
                  color: c.textCaption,
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderSubtle),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: _separated(rows, c.borderSubtle),
          ),
        ),
      ],
    );
  }

  static List<Widget> _separated(List<Widget> rows, Color dividerColor) {
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Divider(
          color: dividerColor,
          height: 1,
          indent: 16,
        ));
      }
    }
    return result;
  }
}

// ── Row types ──────────────────────────────────────────────────────────────────

class _ArrowRow extends StatelessWidget {
  const _ArrowRow({required this.label, this.hint, this.value, this.onTap});

  final String label;
  final String? hint;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textOnParchment,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: AppTypography.amharicCaption.copyWith(
                  color: c.textMuted,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: c.textCaption,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.primary,
            activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.amharicLabel.copyWith(
                color: c.textOnParchment,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.primary, width: 0.8),
              ),
              child: Text(
                actionLabel,
                style: AppTypography.amharicCaption.copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language picker row ────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.s, required this.isAmharic});

  final AppStrings s;
  final bool isAmharic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            s.settingLanguage,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textOnParchment,
            ),
          ),
          const Spacer(),
          _LangChip(
            label: s.langAmharic,
            selected: isAmharic,
            onTap: () => L10n.switchLanguage(context, AppLanguage.amharic),
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: s.langEnglish,
            selected: !isAmharic,
            onTap: () => L10n.switchLanguage(context, AppLanguage.english),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: selected ? Colors.white : c.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
