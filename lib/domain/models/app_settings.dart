import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/theme/reading_theme.dart';
import 'book.dart';

enum AppThemeModePref { system, light, dark }

enum PageTurnMode { scroll, paged }

enum LibraryLayout { list, grid }

/// CJK horizontal (横排) vs vertical (竖排) writing for text-based readers.
enum WritingMode { horizontal, vertical }

class AppSettings extends Equatable {
  const AppSettings({
    this.localeCode = 'zh',
    this.themeMode = AppThemeModePref.system,
    this.fontSize = 19,
    this.lineHeight = 1.75,
    this.readingTheme = ReadingThemeMode.day,
    this.seedColorValue = 0xFF2E7D32,
    this.glassBlur = 1.0,
    this.pageTurnMode = PageTurnMode.scroll,
    this.writingMode = WritingMode.horizontal,
    this.customFontFamily,
    this.horizontalMargin = 22,
    this.paragraphSpacing = 14,
    this.defaultSort = BookSort.added,
    this.libraryLayout = LibraryLayout.list,
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
  final WritingMode writingMode;

  /// Null / empty → bundled NotoSansSC. Otherwise a registered custom family.
  final String? customFontFamily;

  /// Horizontal padding for body text (light-novel comfort).
  final double horizontalMargin;

  /// Extra space between paragraphs in scroll mode.
  final double paragraphSpacing;
  final BookSort defaultSort;
  final LibraryLayout libraryLayout;

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
    WritingMode? writingMode,
    String? customFontFamily,
    bool clearCustomFont = false,
    double? horizontalMargin,
    double? paragraphSpacing,
    BookSort? defaultSort,
    LibraryLayout? libraryLayout,
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
      writingMode: writingMode ?? this.writingMode,
      customFontFamily: clearCustomFont
          ? null
          : (customFontFamily ?? this.customFontFamily),
      horizontalMargin: horizontalMargin ?? this.horizontalMargin,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      defaultSort: defaultSort ?? this.defaultSort,
      libraryLayout: libraryLayout ?? this.libraryLayout,
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
    writingMode,
    customFontFamily,
    horizontalMargin,
    paragraphSpacing,
    defaultSort,
    libraryLayout,
    libraryPinEnabled,
    showReadingDuration,
  ];
}
