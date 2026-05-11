import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/widgets/brand_mark.dart';

void main() {
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'መጽሐፍ ቅዱስ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _DesignSystemPreview(),
    );
  }
}

/// Temporary preview screen – replace with real navigation once screens exist.
class _DesignSystemPreview extends StatefulWidget {
  const _DesignSystemPreview();

  @override
  State<_DesignSystemPreview> createState() => _DesignSystemPreviewState();
}

class _DesignSystemPreviewState extends State<_DesignSystemPreview> {
  bool _parchmentMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _parchmentMode ? AppTheme.parchment : AppTheme.light,
      child: Builder(builder: (context) {
        final bg = _parchmentMode
            ? AppColors.parchment
            : AppColors.surface;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: const Text('መጽሐፍ ቅዱስ'),
            actions: [
              const BrandMark(size: 22),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Brand mark ───────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    BrandMark(
                      size: 56,
                      color: AppColors.primary,
                      showLabel: true,
                    ),
                    const SizedBox(height: 24),
                    const LiturgicalDivider(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Parchment mode toggle ────────────────────────────────────
              SwitchListTile(
                title: Text(
                  'Parchment Mode',
                  style: AppTypography.englishLabel
                      .copyWith(color: AppColors.textBody),
                ),
                subtitle: Text(
                  'Soft off-white background for reading',
                  style: AppTypography.englishCaption
                      .copyWith(color: AppColors.textMuted),
                ),
                value: _parchmentMode,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _parchmentMode = v),
              ),
              const LiturgicalDivider(),
              const SizedBox(height: 16),

              // ── Typography scale ─────────────────────────────────────────
              Text('Typography',
                  style: AppTypography.englishHeading
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Text('በዓለ ትምህርት', style: AppTypography.amharicDisplay
                  .copyWith(color: AppColors.textOnParchment)),
              Text('amharicDisplay · 28 / 700', style: AppTypography.englishCaption
                  .copyWith(color: AppColors.textCaption)),
              const SizedBox(height: 8),
              Text('መጽሐፈ ዘፍጥረት', style: AppTypography.amharicHeading
                  .copyWith(color: AppColors.textOnParchment)),
              Text('amharicHeading · 22 / 600', style: AppTypography.englishCaption
                  .copyWith(color: AppColors.textCaption)),
              const SizedBox(height: 8),
              Text(
                'በመጀመሪያ እግዚአብሔር ሰማይና ምድርን ፈጠረ።',
                style: AppTypography.amharicVerse
                    .copyWith(color: AppColors.textOnParchment),
              ),
              Text('amharicVerse · 17 / 400 · lh 2.0', style: AppTypography.englishCaption
                  .copyWith(color: AppColors.textCaption)),
              const SizedBox(height: 16),

              // ── Colour swatches ──────────────────────────────────────────
              const LiturgicalDivider(),
              const SizedBox(height: 16),
              Text('Colours',
                  style: AppTypography.englishHeading
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              _ColorRow(label: 'Primary',      color: AppColors.primary),
              _ColorRow(label: 'Primary Light',color: AppColors.primaryLight),
              _ColorRow(label: 'Primary Dark', color: AppColors.primaryDark),
              _ColorRow(label: 'Accent',       color: AppColors.accent,
                  textColor: AppColors.textOnParchment),
              _ColorRow(label: 'Accent Dark',  color: AppColors.accentDark,
                  textColor: AppColors.textOnParchment),
              _ColorRow(label: 'Parchment',    color: AppColors.parchment,
                  textColor: AppColors.textOnParchment),
              const SizedBox(height: 16),

              // ── Testament badges ─────────────────────────────────────────
              const LiturgicalDivider(),
              const SizedBox(height: 16),
              Text('Testament Badges',
                  style: AppTypography.englishHeading
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  TestamentBadge(testament: 'old'),
                  SizedBox(width: 8),
                  TestamentBadge(testament: 'new'),
                ],
              ),
              const SizedBox(height: 16),

              // ── Buttons ──────────────────────────────────────────────────
              const LiturgicalDivider(),
              const SizedBox(height: 16),
              Text('Buttons',
                  style: AppTypography.englishHeading
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () {}, child: const Text('አንብብ')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () {}, child: const Text('ፈልግ')),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    this.textColor = AppColors.textOnDark,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: AppTypography.englishLabel.copyWith(color: textColor),
      ),
    );
  }
}
