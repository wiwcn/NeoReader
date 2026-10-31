import 'package:flutter/material.dart';

/// Soft MD3 wash so frosted glass has contrast to blur.
///
/// Light mode stays near the first-version gray-green (`0xFFF3F6F3` /
/// `0xFFF5F8F5`) with only a whisper of primary — not neon green/purple orbs.
/// Content glass is pure white translucent; this wash must stay slightly
/// tinted or cards vanish into the background (两层白).
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
                  // First-version soft gray-green — keep primary bleed tiny.
                  const Color(0xFFF5F8F5),
                  const Color(0xFFF3F6F3),
                  Color.lerp(const Color(0xFFF3F6F3), cs.primary, 0.055)!,
                ],
        ),
      ),
      child: child,
    );
  }
}
