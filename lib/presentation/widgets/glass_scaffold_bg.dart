import 'package:flutter/material.dart';

/// Soft MD3 wash so low-opacity frosted glass has contrast to blur.
///
/// Light mode uses neutral cool whites (`FAFBFC` / `F7F8FA`) with a very light
/// primary/tertiary tint so BackdropFilter frost (~0.12–0.18) still reads
/// without a gray-green cast. Subtle orbs add depth without neon speculars.
class GlassScaffoldBackground extends StatelessWidget {
  const GlassScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
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
                      const Color(0xFFFAFBFC),
                      Color.lerp(const Color(0xFFF7F8FA), cs.primary, 0.035)!,
                      Color.lerp(const Color(0xFFF5F6F8), cs.tertiary, 0.03)!,
                    ],
            ),
          ),
        ),
        // Gentle wash orbs — soft enough to avoid 拟物 liquid glass.
        Positioned(
          top: -80,
          right: -40,
          child: _WashOrb(
            diameter: 260,
            color: cs.primary.withValues(alpha: isDark ? 0.14 : 0.045),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -50,
          child: _WashOrb(
            diameter: 220,
            color: cs.tertiary.withValues(alpha: isDark ? 0.11 : 0.04),
          ),
        ),
        child,
      ],
    );
  }
}

class _WashOrb extends StatelessWidget {
  const _WashOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
