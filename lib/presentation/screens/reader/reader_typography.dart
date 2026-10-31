import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../domain/models/app_settings.dart';

/// Shared body / title styles for text-based readers (轻小说-friendly defaults).
class ReaderTypography {
  ReaderTypography._();

  static String effectiveFontFamily(AppSettings settings) {
    final custom = settings.customFontFamily;
    if (custom != null && custom.isNotEmpty) return custom;
    return AppTheme.fontFamily;
  }

  static TextStyle body(AppSettings settings, ReadingColors colors) {
    return TextStyle(
      color: colors.foreground,
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      fontFamily: effectiveFontFamily(settings),
      fontFamilyFallback: AppTheme.fontFamilyFallback,
      // Soft hyphenation off — better for CJK light novels.
      fontFeatures: const [],
      letterSpacing: 0.15,
    );
  }

  static TextStyle title(AppSettings settings, ReadingColors colors) {
    return body(settings, colors).copyWith(
      fontSize: settings.fontSize + 5,
      fontWeight: FontWeight.w700,
      height: (settings.lineHeight * 0.95).clamp(1.2, 2.0),
      letterSpacing: 0.4,
    );
  }

  static EdgeInsets bodyPadding(AppSettings settings) {
    final h = settings.horizontalMargin.clamp(12.0, 40.0);
    return EdgeInsets.fromLTRB(h, 12, h, 48);
  }

  /// Soft max content width on large phones / tablets for 轻小说 comfort.
  static Widget constrainWidth({
    required BuildContext context,
    required Widget child,
    double maxWidth = 720,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
