import 'package:flutter/material.dart';

/// Soft gradient + tinted wash so frosted glass has contrast to blur.
/// Avoid near-white flats — white glass cards would vanish (两层白).
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
                      Color.lerp(cs.surface, cs.primary, 0.28)!,
                      Color.lerp(cs.surface, cs.tertiary, 0.20)!,
                    ]
                  : [
                      const Color(0xFFD5E3D8),
                      Color.lerp(const Color(0xFFE2ECE5), cs.primary, 0.28)!,
                      Color.lerp(const Color(0xFFE8E2F0), cs.tertiary, 0.24)!,
                    ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: _WashOrb(
            diameter: 300,
            color: cs.primary.withValues(alpha: isDark ? 0.22 : 0.20),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -70,
          child: _WashOrb(
            diameter: 240,
            color: cs.tertiary.withValues(alpha: isDark ? 0.18 : 0.16),
          ),
        ),
        Positioned(
          bottom: -30,
          right: 30,
          child: _WashOrb(
            diameter: 180,
            color: cs.secondary.withValues(alpha: isDark ? 0.12 : 0.11),
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
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
