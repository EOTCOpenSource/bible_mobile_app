import 'package:flutter/material.dart';

/// A reusable accessibility wrapper widget for interactive components.
/// Ensures standard 48x48dp minimum touch target, [Semantics] screen reader
/// announcements, and hides visual inner icons via [ExcludeSemantics].
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.button = true,
    this.selected,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool button;
  final bool? selected;
  final double minWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Center(
        child: ExcludeSemantics(
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    return Semantics(
      button: button,
      selected: selected,
      label: label,
      child: content,
    );
  }
}
