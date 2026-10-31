import 'package:flutter/material.dart';

enum ReadingThemeMode { day, night, sepia }

class ReadingColors {
  const ReadingColors({
    required this.background,
    required this.foreground,
    this.muted,
  });

  final Color background;
  final Color foreground;
  final Color? muted;

  Color get secondary => muted ?? foreground.withValues(alpha: 0.65);

  static ReadingColors of(ReadingThemeMode mode) {
    switch (mode) {
      case ReadingThemeMode.day:
        return const ReadingColors(
          background: Color(0xFFFFFFF8),
          foreground: Color(0xFF1A1A1A),
          muted: Color(0xFF5C5C5C),
        );
      case ReadingThemeMode.night:
        // Low-blue night: warm dark charcoal + soft off-white (not pure black).
        return const ReadingColors(
          background: Color(0xFF1A1B1E),
          foreground: Color(0xFFE8E6E3),
          muted: Color(0xFFA8A6A3),
        );
      case ReadingThemeMode.sepia:
        return const ReadingColors(
          background: Color(0xFFF4ECD8),
          foreground: Color(0xFF5B4636),
          muted: Color(0xFF8A7360),
        );
    }
  }
}
