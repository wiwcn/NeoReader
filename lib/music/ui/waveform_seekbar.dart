import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/waveform_cache.dart';

/// Real amplitude waveform seekbar with scrub hit-testing + local magnify.
///
/// G8: paints ≤ [WaveformCache.maxDrawBars]; no BackdropFilter here.
class WaveformSeekBar extends StatefulWidget {
  const WaveformSeekBar({
    super.key,
    required this.peaks,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.playedColor,
    this.unplayedColor,
    this.height = 56,
    this.enablePulse = true,
    this.enableBreathing = true,
    this.playing = false,
  });

  final Float32List? peaks;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final Color? playedColor;
  final Color? unplayedColor;
  final double height;
  final bool enablePulse;
  final bool enableBreathing;
  final bool playing;

  @override
  State<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends State<WaveformSeekBar>
    with SingleTickerProviderStateMixin {
  double? _scrubFrac;
  double? _scrubDx;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncBreath();
  }

  @override
  void didUpdateWidget(covariant WaveformSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _syncBreath();
  }

  void _syncBreath() {
    if (!widget.playing && widget.enableBreathing) {
      _breath.repeat(reverse: true);
    } else {
      _breath.stop();
      _breath.value = 1;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  double get _progress {
    if (_scrubFrac != null) return _scrubFrac!.clamp(0.0, 1.0);
    final total = widget.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _seekToDx(double dx, double width) {
    final frac = (dx / width).clamp(0.0, 1.0);
    setState(() {
      _scrubFrac = frac;
      _scrubDx = dx;
    });
  }

  void _commit(double width) {
    final frac = _scrubFrac ?? _progress;
    final ms = (widget.duration.inMilliseconds * frac).round();
    widget.onSeek(Duration(milliseconds: ms));
    setState(() {
      _scrubFrac = null;
      _scrubDx = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final played = widget.playedColor ?? cs.primary;
    final unplayed = widget.unplayedColor ?? cs.onSurface.withValues(alpha: 0.22);
    final peaks = widget.peaks == null
        ? null
        : WaveformCache.downsample(widget.peaks!, WaveformCache.maxDrawBars);

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final breath = widget.playing
            ? 1.0
            : (0.72 + 0.28 * _breath.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => _seekToDx(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _seekToDx(d.localPosition.dx, w),
              onHorizontalDragEnd: (_) => _commit(w),
              onTapDown: (d) => _seekToDx(d.localPosition.dx, w),
              onTapUp: (_) => _commit(w),
              child: SizedBox(
                height: widget.height,
                width: w,
                child: CustomPaint(
                  painter: _WavePainter(
                    peaks: peaks,
                    progress: _progress,
                    played: played,
                    unplayed: unplayed,
                    scrubDx: _scrubDx,
                    magnify: _scrubDx != null,
                    breath: breath,
                    pulse: widget.playing && widget.enablePulse,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.peaks,
    required this.progress,
    required this.played,
    required this.unplayed,
    required this.scrubDx,
    required this.magnify,
    required this.breath,
    required this.pulse,
  });

  final Float32List? peaks;
  final double progress;
  final Color played;
  final Color unplayed;
  final double? scrubDx;
  final bool magnify;
  final double breath;
  final bool pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final bars = peaks;
    if (bars == null || bars.isEmpty) {
      // Flat fallback line (still scrubbable).
      final y = mid;
      final paintU = Paint()
        ..color = unplayed
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final paintP = Paint()
        ..color = played
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintU);
      canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), paintP);
      _playhead(canvas, size, size.width * progress, played);
      return;
    }

    final n = bars.length;
    final gap = 1.5;
    final barW = math.max(1.5, (size.width - gap * (n - 1)) / n);
    final maxH = size.height * 0.92 * breath;

    for (var i = 0; i < n; i++) {
      final x = i * (barW + gap);
      var h = (bars[i].clamp(0.05, 1.0)) * maxH;
      // Scrub local magnify around finger.
      if (magnify && scrubDx != null) {
        final dist = (x + barW / 2 - scrubDx!).abs();
        final radius = size.width * 0.12;
        if (dist < radius) {
          final t = 1 - dist / radius;
          h *= 1 + 0.85 * Curves.easeOut.transform(t);
        }
      }
      final frac = (x + barW / 2) / size.width;
      final paint = Paint()
        ..color = frac <= progress ? played : unplayed
        ..style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barW / 2, mid),
          width: barW,
          height: h,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }

    _playhead(canvas, size, size.width * progress, played);
  }

  void _playhead(Canvas canvas, Size size, double x, Color color) {
    final glow = Paint()
      ..color = color.withValues(alpha: pulse ? 0.35 : 0.2)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(Offset(x, size.height / 2), pulse ? 7 : 5, glow);
    final core = Paint()..color = color;
    canvas.drawCircle(Offset(x, size.height / 2), 3.5, core);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.peaks != peaks ||
      old.progress != progress ||
      old.scrubDx != scrubDx ||
      old.breath != breath ||
      old.pulse != pulse ||
      old.played != played ||
      old.unplayed != unplayed;
}
