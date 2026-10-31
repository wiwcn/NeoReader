import 'package:flutter/material.dart';

/// Soft MD3 gradient backdrop so frosted glass has something to blur.
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  cs.surface,
                  Color.lerp(cs.surface, cs.primary, 0.18)!,
                  Color.lerp(cs.surface, cs.tertiary, 0.12)!,
                ]
              : [
                  const Color(0xFFF5F8F5),
                  Color.lerp(Colors.white, cs.primary, 0.12)!,
                  Color.lerp(Colors.white, cs.tertiary, 0.10)!,
                ],
        ),
      ),
      child: child,
    );
  }
}
