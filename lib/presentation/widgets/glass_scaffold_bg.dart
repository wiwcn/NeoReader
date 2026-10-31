import 'package:flutter/material.dart';

/// Soft MD3 surface backdrop. Mild tint only — list body stays flat (PiliPlus).
class GlassScaffoldBackground extends StatelessWidget {
  const GlassScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  cs.surface,
                  Color.lerp(cs.surface, cs.primary, 0.08)!,
                ]
              : [
                  // M3 surface / surfaceContainerLowest — less muddy green-white.
                  cs.surface,
                  cs.surfaceContainerLowest,
                  Color.lerp(cs.surfaceContainerLowest, cs.primary, 0.04)!,
                ],
        ),
      ),
      child: child,
    );
  }
}
