import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'reading_settings_page.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isAmharic = s is AmStrings;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _MeAppBar(s: s)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _ProfileCard(s: s)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Reading ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionReading,
              enLabel: 'READING',
              rows: [
                _ArrowRow(
                  label: s.settingTranslation,
                  value: s.settingTranslationValue,
                ),
                _ArrowRow(
                  label: s.settingReadingPrefs,
                  hint: s.settingReadingPrefsHint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReadingSettingsPage(),
                    ),
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
              rows: [_LanguageRow(s: s, isAmharic: isAmharic)],
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
                // Daily Verse
                _TimePickerRow(
                  label: s.settingDailyVerse,
                  hint: s.settingDailyVerseHint,
                  enabled: settings.dailyVerseNotificationEnabled,
                  time: settings.dailyVerseNotificationTime,
                  defaultTime: const TimeOfDay(hour: 6, minute: 0),
                  onToggle: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final notifier = Settings.notifierOf(context);
                    if (v) {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (!granted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission denied'),
                          ),
                        );
                        return;
                      }
                    }
                    notifier.value = notifier.value.copyWith(
                      dailyVerseNotificationEnabled: v,
                    );
                    if (v) {
                      final time =
                          settings.dailyVerseNotificationTime ??
                          const TimeOfDay(hour: 6, minute: 0);
                      await NotificationService.instance.scheduleDailyVerse(
                        time,
                        s.settingDailyVerse,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Daily verse set for ${time.formatted}',
                          ),
                        ),
                      );
                    } else {
                      await NotificationService.instance.cancel(
                        NotificationConfig.dailyVerseId,
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Daily verse reminder off'),
                        ),
                      );
                    }
                  },
                  onTimePicked: (picked) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(dailyVerseNotificationTime: picked),
                    );
                    await NotificationService.instance.scheduleDailyVerse(
                      picked,
                      s.settingDailyVerse,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ Daily verse updated to ${picked.formatted}',
                        ),
                      ),
                    );
                  },
                ),
                // Reading Reminder
                _TimePickerRow(
                  label: s.settingReadingTime,
                  hint: s.settingReadingTimeHint,
                  enabled: settings.readingTimeNotificationEnabled,
                  time: settings.readingTimeNotificationTime,
                  defaultTime: const TimeOfDay(hour: 20, minute: 0),
                  onToggle: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final notifier = Settings.notifierOf(context);
                    if (v) {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (!granted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission denied'),
                          ),
                        );
                        return;
                      }
                    }
                    notifier.value = notifier.value.copyWith(
                      readingTimeNotificationEnabled: v,
                    );
                    if (v) {
                      final time =
                          settings.readingTimeNotificationTime ??
                          const TimeOfDay(hour: 20, minute: 0);
                      await NotificationService.instance.scheduleReadingReminder(
                        time,
                        s.settingReadingTime,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Reading reminder set for ${time.formatted}',
                          ),
                        ),
                      );
                    } else {
                      await NotificationService.instance.cancel(
                        NotificationConfig.readingReminderId,
                      );
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Reading reminder off'),
                        ),
                      );
                    }
                  },
                  onTimePicked: (picked) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(readingTimeNotificationTime: picked),
                    );
                    await NotificationService.instance.scheduleReadingReminder(
                      picked,
                      s.settingReadingTime,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ Reading reminder updated to ${picked.formatted}',
                        ),
                      ),
                    );
                  },
                ),
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
  const _ProfileCard({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {},
        child: Builder(
          builder: (context) {
            final c = context.colors;
            return Container(
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
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'ን',
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + info + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ነህምያ ተስፋዬ',
                          style: TextStyle(
                            fontFamily: AppTypography.shiromeda,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'nehemiah@email.com  •  12 ቀናት',
                          style: AppTypography.amharicCaption.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
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
            );
          },
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
          child: Column(children: _separated(rows, c.borderSubtle)),
        ),
      ],
    );
  }

  static List<Widget> _separated(List<Widget> rows, Color dividerColor) {
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Divider(color: dividerColor, height: 1, indent: 16));
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
            Icon(Icons.chevron_right_rounded, color: c.textCaption, size: 20),
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

// ── Notification time-picker row ─────────────────────────────────────────────

/// A settings row combining an enable/disable [Switch] with a tappable time
/// chip. When enabled the chip opens the system time picker; when disabled it
/// is greyed-out and non-interactive. An internal [_busy] flag prevents double
/// taps and shows a small [CircularProgressIndicator] while async work runs.
class _TimePickerRow extends StatefulWidget {
  const _TimePickerRow({
    required this.label,
    this.hint,
    required this.enabled,
    this.time,
    required this.defaultTime,
    required this.onToggle,
    required this.onTimePicked,
  });

  final String label;
  final String? hint;

  /// Whether the notification is currently enabled.
  final bool enabled;

  /// Currently stored time; [defaultTime] is displayed when null.
  final TimeOfDay? time;

  /// Fallback displayed when [time] is null.
  final TimeOfDay defaultTime;

  /// Called when the switch is flipped. Owns permission requests, scheduling,
  /// and snackbars. Return normally to confirm; the [_busy] guard is released
  /// automatically.
  final Future<void> Function(bool enabled) onToggle;

  /// Called with the newly-chosen time after the system picker confirms.
  final Future<void> Function(TimeOfDay time) onTimePicked;

  @override
  State<_TimePickerRow> createState() => _TimePickerRowState();
}

class _TimePickerRowState extends State<_TimePickerRow> {
  bool _busy = false;

  Future<void> _handleToggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onToggle(v);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    if (_busy || !widget.enabled) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.time ?? widget.defaultTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onTimePicked(picked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final displayTime = (widget.time ?? widget.defaultTime).formatted;
    final isOn = widget.enabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          // Label + hint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                  ),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.hint!,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tappable time chip
          GestureDetector(
            onTap: isOn && !_busy ? _pickTime : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOn
                    ? c.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOn ? c.primary : c.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isOn ? c.primary : c.textCaption,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayTime,
                    style: AppTypography.amharicCaption.copyWith(
                      color: isOn ? c.primary : c.textCaption,
                      fontWeight:
                          isOn ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Switch or loading indicator
          if (_busy)
            const SizedBox(
              width: 40,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Switch(
              value: isOn,
              onChanged: _handleToggle,
              activeThumbColor: c.primary,
              activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
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
