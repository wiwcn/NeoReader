import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Cover-derived dual role colors for 绚丽模式 (inspired by Folia builtin theme,
/// original Flutter implementation — not a port of Folia source).
@immutable
class CoverTheme {
  const CoverTheme({
    required this.background,
    required this.primary,
    required this.accent,
    required this.secondary,
    required this.wash,
  });

  /// Deep tinted stage ground.
  final Color background;

  /// High-contrast lyric / title text.
  final Color primary;

  /// Controls, waveform played, highlights.
  final Color accent;

  /// Soft secondary text / orbs.
  final Color secondary;

  /// Mid wash for gradients (between bg and accent).
  final Color wash;

  static const fallback = CoverTheme(
    background: Color(0xFF0A0C12),
    primary: Color(0xFFF2F4F8),
    accent: Color(0xFF7EB6FF),
    secondary: Color(0xFFA8B0C0),
    wash: Color(0xFF1A2740),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverTheme &&
          background == other.background &&
          primary == other.primary &&
          accent == other.accent &&
          secondary == other.secondary &&
          wash == other.wash;

  @override
  int get hashCode => Object.hash(background, primary, accent, secondary, wash);
}

/// Extracts and caches a [CoverTheme] from a local cover image path.
class CoverThemeCache {
  CoverThemeCache._();
  static final CoverThemeCache instance = CoverThemeCache._();

  final Map<String, CoverTheme> _cache = {};
  final Map<String, Future<CoverTheme>> _inflight = {};

  CoverTheme? peek(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) return null;
    return _cache[coverPath];
  }

  Future<CoverTheme> resolve(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) {
      return Future.value(CoverTheme.fallback);
    }
    final hit = _cache[coverPath];
    if (hit != null) return Future.value(hit);
    return _inflight.putIfAbsent(coverPath, () => _extract(coverPath));
  }

  Future<CoverTheme> _extract(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return CoverTheme.fallback;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 96,
        targetHeight: 96,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final generator = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 12,
      );
      image.dispose();
      codec.dispose();

      final theme = _themeFromPalette(generator);
      _cache[path] = theme;
      _inflight.remove(path);
      return theme;
    } catch (_) {
      _inflight.remove(path);
      return CoverTheme.fallback;
    }
  }

  /// Build dark-stage roles from palette_generator swatches.
  static CoverTheme _themeFromPalette(PaletteGenerator g) {
    final vibrant = g.vibrantColor?.color ??
        g.lightVibrantColor?.color ??
        g.dominantColor?.color;
    final muted = g.darkMutedColor?.color ??
        g.mutedColor?.color ??
        g.dominantColor?.color;
    final dominant = g.dominantColor?.color ?? vibrant ?? muted;

    if (dominant == null && vibrant == null) {
      return CoverTheme.fallback;
    }

    final base = vibrant ?? dominant ?? CoverTheme.fallback.accent;
    final support = muted ?? dominant ?? base;

    final baseHsl = HSLColor.fromColor(base);
    final supportHsl = HSLColor.fromColor(support);

    // Prefer a saturated mid-lightness hue as the identity (cover "vibe").
    final identity = baseHsl.saturation > 0.12
        ? baseHsl
        : (supportHsl.saturation > baseHsl.saturation ? supportHsl : baseHsl);

    var accentHue = identity.hue;
    // If support is meaningfully different, lean accent toward it.
    final hueDist = _hueDistance(identity.hue, supportHsl.hue);
    if (hueDist >= 25 && hueDist <= 160 && supportHsl.saturation > 0.15) {
      accentHue = supportHsl.hue;
    } else {
      // Analogous nudge so monochrome covers still get a second color.
      accentHue = (identity.hue + 28) % 360;
    }

    final background = HSLColor.fromAHSL(
      1,
      identity.hue,
      (identity.saturation * 0.55).clamp(0.18, 0.45),
      0.09,
    ).toColor();

    final wash = HSLColor.fromAHSL(
      1,
      identity.hue,
      (identity.saturation * 0.7).clamp(0.22, 0.55),
      0.22,
    ).toColor();

    final accent = HSLColor.fromAHSL(
      1,
      accentHue,
      0.72,
      0.62,
    ).toColor();

    final secondary = HSLColor.fromAHSL(
      1,
      _lerpHue(identity.hue, accentHue, 0.35),
      0.28,
      0.70,
    ).toColor();

    final primary = HSLColor.fromAHSL(
      1,
      identity.hue,
      0.12,
      0.94,
    ).toColor();

    return CoverTheme(
      background: background,
      primary: primary,
      accent: accent,
      secondary: secondary,
      wash: wash,
    );
  }

  static double _hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  static double _lerpHue(double from, double to, double t) {
    var delta = ((to - from + 540) % 360) - 180;
    return (from + delta * t) % 360;
  }
}
