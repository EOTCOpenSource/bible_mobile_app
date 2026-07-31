import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book.dart';

/// The critical apparatus for one verse: its translator footnotes and its
/// parallel-passage cross references.
///
/// Kept behind a tap rather than printed inline because a verse like Genesis
/// 1:1 carries fourteen references, which would swamp the text it belongs to.
class VerseApparatusSheet extends StatelessWidget {
  const VerseApparatusSheet({
    super.key,
    required this.reference,
    required this.refs,
    required this.notes,
    required this.s,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.bodyFont,
  });

  final String reference;
  final List<CrossRef> refs;
  final List<VerseNote> notes;
  final AppStrings s;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final String bodyFont;

  @override
  Widget build(BuildContext context) {
    final bodies = notes.map((n) => n.body).where((b) => b.isNotEmpty).toList();
    final targets =
        refs.map((r) => r.target).where((t) => t.isNotEmpty).toList();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              reference,
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: 11,
                letterSpacing: 1.0,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bodies.isNotEmpty) ...[
                      _SectionLabel(
                        text: s.verseFootnotes,
                        color: mutedColor,
                      ),
                      for (final body in bodies)
                        _ApparatusEntry(
                          marker: '✻',
                          text: body,
                          bodyFont: bodyFont,
                          textColor: textColor,
                          accentColor: accentColor,
                        ),
                      if (targets.isNotEmpty) const SizedBox(height: 18),
                    ],
                    if (targets.isNotEmpty) ...[
                      _SectionLabel(
                        text: s.verseCrossReferences,
                        color: mutedColor,
                      ),
                      for (final target in targets)
                        _ApparatusEntry(
                          marker: '→',
                          text: target,
                          bodyFont: bodyFont,
                          textColor: textColor,
                          accentColor: accentColor,
                        ),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: 9,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      );
}

class _ApparatusEntry extends StatelessWidget {
  const _ApparatusEntry({
    required this.marker,
    required this.text,
    required this.bodyFont,
    required this.textColor,
    required this.accentColor,
  });

  final String marker;
  final String text;
  final String bodyFont;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Text(
                marker,
                style: TextStyle(fontSize: 12, color: accentColor),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: bodyFont,
                  fontSize: 14,
                  height: 1.7,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
}
