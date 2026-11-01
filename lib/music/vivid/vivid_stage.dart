import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui/cover_image.dart';
import 'cover_theme.dart';
import 'lrc_parser.dart';

/// Immersive Folia-inspired stage: blurred cover wash + 流光-like lyric focus.
class VividStageBackdrop extends StatelessWidget {
  const VividStageBackdrop({
    super.key,
    required this.coverPath,
    required this.theme,
    required this.tick,
  });

  final String? coverPath;
  final CoverTheme theme;
  final double tick; // 0..1 ambient phase

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.background),
        if (coverPath != null && coverPath!.isNotEmpty)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.18,
              child: CoverImage(path: coverPath, fit: BoxFit.cover),
            ),
          ),
        // Color wash over blurred cover.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.background.withValues(alpha: 0.55),
                theme.wash.withValues(alpha: 0.72),
                theme.background.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Soft flowing orbs (流光 ambient).
        CustomPaint(
          painter: _FlowWashPainter(
            theme: theme,
            tick: tick,
          ),
        ),
        // Bottom vignette so chrome stays readable.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.background.withValues(alpha: 0.15),
                theme.background.withValues(alpha: 0.82),
              ],
              stops: const [0.35, 0.62, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowWashPainter extends CustomPainter {
  _FlowWashPainter({required this.theme, required this.tick});

  final CoverTheme theme;
  final double tick;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tick * math.pi * 2;
    final blobs = <(Offset, double, Color)>[
      (
        Offset(
          size.width * (0.25 + 0.08 * math.sin(t)),
          size.height * (0.28 + 0.06 * math.cos(t * 0.9)),
        ),
        size.shortestSide * 0.55,
        theme.accent.withValues(alpha: 0.22),
      ),
      (
        Offset(
          size.width * (0.78 + 0.06 * math.cos(t * 1.1)),
          size.height * (0.42 + 0.08 * math.sin(t * 0.7)),
        ),
        size.shortestSide * 0.48,
        theme.secondary.withValues(alpha: 0.16),
      ),
      (
        Offset(
          size.width * (0.5 + 0.1 * math.sin(t * 0.6 + 1)),
          size.height * (0.7 + 0.05 * math.cos(t * 1.3)),
        ),
        size.shortestSide * 0.62,
        theme.wash.withValues(alpha: 0.28),
      ),
    ];

    for (final (c, r, color) in blobs) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [color, color.withValues(alpha: 0)],
        );
      canvas.drawCircle(c, r, paint);
    }

    // Soft color blocks (凝彩-lite spirit): slow drifting rects.
    final blockPaint = Paint()..style = PaintingStyle.fill;
    final blockW = size.width * 0.22;
    final blockH = size.height * 0.08;
    final bx = size.width * (0.12 + 0.04 * math.sin(t * 0.5));
    final by = size.height * (0.18 + 0.03 * math.cos(t * 0.8));
    blockPaint.color = theme.accent.withValues(alpha: 0.10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, blockW, blockH),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    blockPaint.color = theme.secondary.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * (0.62 + 0.03 * math.cos(t * 0.4)),
          size.height * (0.55 + 0.04 * math.sin(t * 0.55)),
          blockW * 0.85,
          blockH * 1.2,
        ),
        const Radius.circular(10),
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowWashPainter old) =>
      old.tick != tick || old.theme != theme;
}

/// Large lyric focus — synced LRC or kinetic title/artist fallback.
class VividLyricFocus extends StatelessWidget {
  const VividLyricFocus({
    super.key,
    required this.theme,
    required this.title,
    required this.artist,
    required this.lines,
    required this.position,
    required this.emptyHint,
    required this.breath,
  });

  final CoverTheme theme;
  final String title;
  final String artist;
  final List<LyricLine> lines;
  final Duration position;
  final String emptyHint;
  final double breath; // 0..1

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return _KineticMeta(
        theme: theme,
        title: title,
        artist: artist,
        emptyHint: emptyHint,
        breath: breath,
      );
    }

    final idx = LrcParser.activeIndex(lines, position);
    final prev = idx > 0 ? lines[idx - 1].text : null;
    final current = idx >= 0 ? lines[idx].text : (lines.isNotEmpty ? lines.first.text : '');
    final next = (idx >= 0 && idx + 1 < lines.length)
        ? lines[idx + 1].text
        : (idx < 0 && lines.isNotEmpty ? lines.first.text : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prev != null)
            Opacity(
              opacity: 0.35,
              child: Text(
                prev,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.secondary,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              key: ValueKey<String>(current),
              current,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.primary,
                fontSize: 28,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: theme.accent.withValues(alpha: 0.55),
                    blurRadius: 22,
                  ),
                  Shadow(
                    color: theme.accent.withValues(alpha: 0.25),
                    blurRadius: 48,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (next != null)
            Opacity(
              opacity: 0.42,
              child: Text(
                next,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.secondary,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KineticMeta extends StatelessWidget {
  const _KineticMeta({
    required this.theme,
    required this.title,
    required this.artist,
    required this.emptyHint,
    required this.breath,
  });

  final CoverTheme theme;
  final String title;
  final String artist;
  final String emptyHint;
  final double breath;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.018 * math.sin(breath * math.pi * 2);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.primary,
                fontSize: 32,
                height: 1.25,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: theme.accent.withValues(alpha: 0.5),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            emptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.secondary.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
