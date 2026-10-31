import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/theme/reading_theme.dart';
import 'book.dart';

enum AppThemeModePref { system, light, dark }

enum PageTurnMode { scroll, paged }

class AppSettings extends Equatable {
  const AppSettings({
    this.localeCode = 'zh',
    this.themeMode = AppThemeModePref.system,
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.readingTheme = ReadingThemeMode.day,
    this.seedColorValue = 0xFF2E7D32,
    this.glassBlur = 1.0,
    this.pageTurnMode = PageTurnMode.scroll,
    this.defaultSort = BookSort.added,
    this.libraryPinEnabled = false,
    this.showReadingDuration = true,
  });

  final String localeCode;
  final AppThemeModePref themeMode;
  final double fontSize;
  final double lineHeight;
  final ReadingThemeMode readingTheme;
  final int seedColorValue;
  /// 0.0–2.0 multiplier for frosted glass blur.
  final double glassBlur;
  final PageTurnMode pageTurnMode;
  final BookSort defaultSort;
  /// Roadmap placeholder — library lock / PIN.
  final bool libraryPinEnabled;
  final bool showReadingDuration;

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
    double? glassBlur,
    PageTurnMode? pageTurnMode,
    BookSort? defaultSort,
    bool? libraryPinEnabled,
    bool? showReadingDuration,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      readingTheme: readingTheme ?? this.readingTheme,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      glassBlur: glassBlur ?? this.glassBlur,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
      defaultSort: defaultSort ?? this.defaultSort,
      libraryPinEnabled: libraryPinEnabled ?? this.libraryPinEnabled,
      showReadingDuration: showReadingDuration ?? this.showReadingDuration,
    );
  }

  @override
  List<Object?> get props => [
        localeCode,
        themeMode,
        fontSize,
        lineHeight,
        readingTheme,
        seedColorValue,
        glassBlur,
        pageTurnMode,
        defaultSort,
        libraryPinEnabled,
        showReadingDuration,
      ];
}
