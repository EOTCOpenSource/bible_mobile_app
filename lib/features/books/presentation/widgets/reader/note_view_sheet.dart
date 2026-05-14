import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';

class NoteViewSheet extends StatelessWidget {
  const NoteViewSheet({
    super.key,
    required this.reference,
    required this.verseText,
    required this.noteContent,
    required this.bodyFont,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.onEdit,
  });

  final String reference;
  final String verseText;
  final String noteContent;
  final String bodyFont;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Reference badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              reference,
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Verse text
          Text(
            verseText,
            style: TextStyle(
              fontFamily: bodyFont,
              fontSize: 15,
              height: 1.75,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(
            color: accentColor.withValues(alpha: 0.2),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 14),

          // Note section header
          Row(
            children: [
              Icon(Icons.sticky_note_2_rounded, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'ማስታወሻ',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Note content card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            child: Text(
              noteContent,
              style: TextStyle(
                fontFamily: bodyFont,
                fontSize: 15,
                height: 1.75,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Edit button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: Icon(Icons.edit_rounded, size: 15, color: accentColor),
              label: Text(
                'ማስታወሻ አርትዕ',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 13,
                  color: accentColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
