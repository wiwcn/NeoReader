import 'package:flutter/material.dart';

enum ReadingThemeMode { day, night, sepia }

class ReadingColors {
  const ReadingColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  static ReadingColors of(ReadingThemeMode mode) {
    switch (mode) {
      case ReadingThemeMode.day:
        return const ReadingColors(
          background: Color(0xFFFFFFF8),
          foreground: Color(0xFF1A1A1A),
        );
      case ReadingThemeMode.night:
        return const ReadingColors(
          background: Color(0xFF121212),
          foreground: Color(0xFFE0E0E0),
        );
      case ReadingThemeMode.sepia:
        return const ReadingColors(
          background: Color(0xFFF4ECD8),
          foreground: Color(0xFF5B4636),
        );
    }
  }
}
