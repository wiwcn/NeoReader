import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Soft MD3 wash so low-opacity frosted glass has contrast to blur.
///
/// Light mode uses neutral cool whites with a very light primary/tertiary tint.
/// Dark mode stays near-black cool neutrals — seed primary/tertiary only whisper
/// so a green seed does not turn the canvas into mud.
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
        // Solid base first — prevents a white flash if the gradient rebuilds
        // during ThemeMode switches (tab content fades over this canvas).
        ColoredBox(color: isDark ? AppTheme.darkCanvas : AppTheme.lightCanvas),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.darkCanvas,
                      Color.lerp(AppTheme.darkContainerLow, cs.primary, 0.055)!,
                      Color.lerp(AppTheme.darkCanvas, cs.tertiary, 0.035)!,
                    ]
                  : [
                      AppTheme.lightCanvas,
                      Color.lerp(AppTheme.lightCanvasMid, cs.primary, 0.035)!,
                      Color.lerp(AppTheme.lightCanvasDeep, cs.tertiary, 0.03)!,
                    ],
            ),
          ),
        ),
        // Gentle wash orbs — restrained alpha (especially dark).
        Positioned(
          top: -80,
          right: -40,
          child: _WashOrb(
            diameter: 260,
            color: cs.primary.withValues(alpha: isDark ? 0.07 : 0.045),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -50,
          child: _WashOrb(
            diameter: 220,
            color: cs.tertiary.withValues(alpha: isDark ? 0.05 : 0.04),
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
