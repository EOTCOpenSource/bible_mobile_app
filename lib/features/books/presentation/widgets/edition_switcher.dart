import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/bible_repository_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/edition.dart';
import '../../providers/edition_providers.dart';
import '../pages/editions_page.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Title in the app's UI language, with the other language as the subtitle.
///
/// The catalog carries both, and which one leads depends on the app language,
/// not on the edition — an English reader looking at `am-2000` wants
/// "Amharic Bible 2000" first and "አዲሱ መደበኛ ትርጉም" underneath.
String editionTitleFor(Edition e, AppStrings s) =>
    s is EnStrings ? e.titleEn : e.title;

String editionSubtitleFor(Edition e, AppStrings s) =>
    s is EnStrings ? e.title : e.titleEn;

/// One accent per language, so nine editions read as five groups at a glance.
Color editionLanguageColor(BuildContext context, String language) {
  final c = context.colors;
  return switch (language) {
    'am' => c.primary,
    // Deeper than the gold accent token: this color carries white text on the
    // filter chips and the hero, and the token is too light to hold it.
    'gez' => const Color(0xFF8A6A24),
    'en' => c.newTestament,
    'ti' => const Color(0xFF2F6B4F),
    'om' => const Color(0xFF8A5A1F),
    _ => c.textMuted,
  };
}

/// Colors for the chooser sheet.
///
/// The reader paints its own shell — dark parchment even when the app theme is
/// light — so every sheet it opens has to be handed those colors rather than
/// reading the theme.
@immutable
class EditionSheetTheme {
  const EditionSheetTheme({
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.border,
  });

  final Color surface;
  final Color text;
  final Color muted;
  final Color accent;
  final Color border;

  factory EditionSheetTheme.of(BuildContext context) {
    final c = context.colors;
    return EditionSheetTheme(
      surface: c.surface,
      text: c.textOnParchment,
      muted: c.textMuted,
      accent: c.primary,
      border: c.borderSubtle,
    );
  }
}

// ── Chooser button ────────────────────────────────────────────────────────────

/// Compact button showing the active edition; opens [showEditionSwitcher].
///
/// Sits in the books list header, the chapter chooser and the reader toolbar so
/// the translation can be changed from wherever the reader notices they are in
/// the wrong one.
class EditionChip extends ConsumerWidget {
  const EditionChip({
    super.key,
    this.background,
    this.foreground,
    this.borderColor,
    this.sheetTheme,
    this.dense = false,
  });

  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final EditionSheetTheme? sheetTheme;

  /// Drops the label to icon + abbreviation only, for the reader toolbar.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final primary = ref.watch(activeEditionTitleProvider).valueOrNull ?? '';
    final parallel = ref.watch(secondaryEditionTitleProvider).valueOrNull;
    // Both editions in the label when reading in parallel — the chip is the
    // only place the second column is named once the reader scrolls past the
    // column headings.
    final label = parallel == null ? primary : '$primary · $parallel';
    final fg = foreground ?? c.primary;
    final bg = background ?? c.primary.withValues(alpha: 0.08);
    final border = borderColor ?? c.primary.withValues(alpha: 0.18);

    return Semantics(
      button: true,
      label: L10n.of(context).editionSwitchTitle,
      child: InkWell(
        onTap: () => showEditionSwitcher(context, theme: sheetTheme),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 11,
            vertical: dense ? 5 : 7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: dense ? 13 : 14, color: fg),
              const SizedBox(width: 5),
              ConstrainedBox(
                // "አማርኛ 2000" fits; a parallel pair needs the extra room.
                constraints: BoxConstraints(
                  maxWidth: (dense ? 92.0 : 124.0) + (parallel == null ? 0 : 60),
                ),
                child: Text(
                  label.isEmpty ? '—' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: dense ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.1,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, size: dense ? 14 : 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chooser sheet ─────────────────────────────────────────────────────────────

/// Opens the edition chooser.
Future<void> showEditionSwitcher(
  BuildContext context, {
  EditionSheetTheme? theme,
}) {
  final resolved = theme ?? EditionSheetTheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditionSwitcherSheet(theme: resolved),
  );
}

class _EditionSwitcherSheet extends ConsumerWidget {
  const _EditionSwitcherSheet({required this.theme});

  final EditionSheetTheme theme;

  Future<void> _use(
    BuildContext context,
    EditionInstall item,
    AppStrings s,
  ) async {
    // Read through the root container, not this sheet's [ref]: the sheet is
    // popped below and its element is gone by the time the switch completes.
    final container = ProviderScope.containerOf(context);
    final repo = container.read(bibleRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title = editionTitleFor(item.edition, s);
    final alreadyActive = item.edition.id == repo.activeEditionId;

    // Close the chooser first. Switching notifies the reader, which may have to
    // leave the book it is on when the new canon does not carry it, and it can
    // only do that while it is the top route.
    Navigator.of(context).pop();
    if (alreadyActive) return;
    if (!await repo.switchEdition(item.edition.id)) return;

    container.read(activeEditionIdProvider.notifier).state =
        repo.activeEditionId;
    // Reading an edition that was the second column drops it from there; the
    // chip and the settings row have to hear about that.
    container.read(secondaryEditionIdProvider.notifier).state =
        repo.secondaryEditionId;
    container.invalidate(editionListProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(s.editionSwitched(title))));
  }

  /// Puts an edition in the reader's second column, or takes it out again.
  ///
  /// Closes the sheet either way: the change is on the page underneath, and a
  /// confirmation snackbar behind an open sheet is a confirmation nobody sees.
  Future<void> _toggleParallel(
    BuildContext context,
    EditionInstall item,
    AppStrings s,
    bool isParallel,
  ) async {
    final container = ProviderScope.containerOf(context);
    final repo = container.read(bibleRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title = editionTitleFor(item.edition, s);
    final target = isParallel ? null : item.edition.id;

    Navigator.of(context).pop();
    if (!await repo.setSecondaryEdition(target)) return;

    container.read(secondaryEditionIdProvider.notifier).state =
        repo.secondaryEditionId;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          target == null ? s.parallelDisabled : s.parallelEnabled(title),
        ),
      ));
  }

  void _manage(BuildContext context) {
    // Root navigator: the books tab has a nested one, and the editions screen
    // is a full page, not something that should sit under the bottom nav.
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    root.push(MaterialPageRoute<void>(builder: (_) => const EditionsPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final activeId = ref.watch(activeEditionIdProvider);
    final parallelId = ref.watch(secondaryEditionIdProvider);
    final listAsync = ref.watch(editionListProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    final installed = listAsync.valueOrNull
            ?.where((i) => i.isInstalled)
            .toList() ??
        const <EditionInstall>[];
    final availableCount =
        listAsync.valueOrNull?.where((i) => !i.isInstalled).length ?? 0;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.editionSwitchTitle,
                          style: AppTypography.amharicSubheading.copyWith(
                            fontSize: 16,
                            color: theme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.editionSwitchSubtitle,
                          style: TextStyle(fontSize: 11.5, color: theme.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: listAsync.isLoading && installed.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: installed.length,
                      itemBuilder: (ctx, i) {
                        final isActive = installed[i].edition.id == activeId;
                        final isParallel =
                            installed[i].edition.id == parallelId;
                        return _SheetRow(
                          item: installed[i],
                          s: s,
                          theme: theme,
                          isActive: isActive,
                          isParallel: isParallel,
                          onTap: () => _use(context, installed[i], s),
                          // An edition cannot be both columns, so the one being
                          // read has no toggle of its own.
                          onToggleParallel: isActive
                              ? null
                              : () => _toggleParallel(
                                    context,
                                    installed[i],
                                    s,
                                    isParallel,
                                  ),
                        );
                      },
                    ),
            ),
            if (installed.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Icon(Icons.view_column_outlined,
                        size: 14, color: theme.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.parallelSectionSubtitle,
                        style: TextStyle(fontSize: 11, color: theme.muted),
                      ),
                    ),
                  ],
                ),
              ),
            Divider(color: theme.border, height: 20, indent: 20, endIndent: 20),
            InkWell(
              onTap: () => _manage(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_outlined,
                        size: 18, color: theme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.editionManage,
                            style: AppTypography.amharicLabel.copyWith(
                              fontSize: 13.5,
                              color: theme.text,
                            ),
                          ),
                          if (availableCount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              s.editionMoreAvailable(availableCount),
                              style:
                                  TextStyle(fontSize: 11, color: theme.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: theme.muted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.item,
    required this.s,
    required this.theme,
    required this.isActive,
    required this.onTap,
    this.isParallel = false,
    this.onToggleParallel,
  });

  final EditionInstall item;
  final AppStrings s;
  final EditionSheetTheme theme;
  final bool isActive;

  /// True when this edition is the reader's second column.
  final bool isParallel;
  final VoidCallback onTap;

  /// Null for the edition being read, which cannot also be the second column.
  final VoidCallback? onToggleParallel;

  @override
  Widget build(BuildContext context) {
    final e = item.edition;
    final langColor = editionLanguageColor(context, e.language);
    final meta = [
      e.languageName,
      if (e.yearLabel.isNotEmpty) e.yearLabel,
      s.editionMetaBooks('${e.books}'),
    ].join('  ·  ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: isActive || isParallel
              ? langColor.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? langColor.withValues(alpha: 0.4)
                : isParallel
                    ? langColor.withValues(alpha: 0.28)
                    : theme.border,
          ),
        ),
        child: Row(
          children: [
            _AbbrevBadge(
              abbrev: e.abbrev.isNotEmpty ? e.abbrev : e.id,
              color: langColor,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    editionTitleFor(e, s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicLabel.copyWith(
                      fontSize: 14,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: theme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (onToggleParallel != null)
              IconButton(
                onPressed: onToggleParallel,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
                tooltip: s.parallelShowAlongside,
                icon: Icon(
                  isParallel
                      ? Icons.view_column_rounded
                      : Icons.view_column_outlined,
                  size: 19,
                  color: isParallel ? langColor : theme.muted,
                ),
              ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Icon(Icons.check_circle_rounded,
                    size: 20, color: langColor),
              )
            else if (item.status == EditionStatus.updateAvailable)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Icon(Icons.sync_problem_rounded,
                    size: 18, color: theme.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square badge carrying an edition's abbreviation.
class _AbbrevBadge extends StatelessWidget {
  const _AbbrevBadge({
    required this.abbrev,
    required this.color,
    this.size = 44,
  });

  final String abbrev;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            abbrev,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.shiromeda,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
        ),
      );
}

/// Shared with the editions screen so the badge looks the same in both places.
class EditionAbbrevBadge extends StatelessWidget {
  const EditionAbbrevBadge({
    super.key,
    required this.abbrev,
    required this.color,
    this.size = 44,
  });

  final String abbrev;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      _AbbrevBadge(abbrev: abbrev, color: color, size: size);
}
