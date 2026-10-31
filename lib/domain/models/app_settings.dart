import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/theme/reading_theme.dart';

enum AppThemeModePref { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.localeCode = 'zh',
    this.themeMode = AppThemeModePref.system,
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.readingTheme = ReadingThemeMode.day,
    this.seedColorValue = 0xFF2E7D32,
  });

  final String localeCode;
  final AppThemeModePref themeMode;
  final double fontSize;
  final double lineHeight;
  final ReadingThemeMode readingTheme;
  final int seedColorValue;

  bool get isZh => localeCode.toLowerCase().startsWith('zh');

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeModePref.system:
        return ThemeMode.system;
      case AppThemeModePref.light:
        return ThemeMode.light;
      case AppThemeModePref.dark:
        return ThemeMode.dark;
    }
  }

  Color get seedColor => Color(seedColorValue);

  AppSettings copyWith({
    String? localeCode,
    AppThemeModePref? themeMode,
    double? fontSize,
    double? lineHeight,
    ReadingThemeMode? readingTheme,
    int? seedColorValue,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      readingTheme: readingTheme ?? this.readingTheme,
      seedColorValue: seedColorValue ?? this.seedColorValue,
    );
  }

  @override
  List<Object?> get props =>
      [localeCode, themeMode, fontSize, lineHeight, readingTheme, seedColorValue];
}
