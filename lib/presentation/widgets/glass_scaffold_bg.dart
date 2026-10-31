import 'package:flutter/material.dart';

/// Soft MD3 wash so low-opacity frosted glass has contrast to blur.
///
/// Light mode stays near the gray-green family (`0xFFF3F6F3`) but with a
/// clearer primary/tertiary tint so BackdropFilter frost (~0.12–0.18) reads.
/// Subtle orbs add depth without neon liquid-glass speculars.
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
                      Color.lerp(cs.surface, cs.primary, 0.22)!,
                      Color.lerp(cs.surface, cs.tertiary, 0.16)!,
                    ]
                  : [
                      const Color(0xFFF5F8F5),
                      Color.lerp(const Color(0xFFF3F6F3), cs.primary, 0.10)!,
                      Color.lerp(const Color(0xFFF0F4F2), cs.tertiary, 0.08)!,
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
            color: cs.primary.withValues(alpha: isDark ? 0.18 : 0.10),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -50,
          child: _WashOrb(
            diameter: 220,
            color: cs.tertiary.withValues(alpha: isDark ? 0.14 : 0.08),
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
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
