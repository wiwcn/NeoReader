import 'dart:ui';

import 'package:flutter/material.dart';

/// Material Design 3 themes with frosted-glass helpers and CJK-capable typography.
///
/// NotoSansSC is applied **only** via [textTheme] / [primaryTextTheme] / nav
/// [labelTextStyle]. Do **not** set [ThemeData.fontFamily] — that makes
/// [Icon] widgets inherit NotoSansSC and render Material Icons as tofu (□).
class AppTheme {
  static const Color seed = Color(0xFF2E7D32);

  /// Bundled Noto Sans SC (assets/fonts). Covers Latin + Simplified Chinese offline.
  static const String fontFamily = 'NotoSansSC';

  /// System CJK fallbacks when a glyph is missing from the bundled face.
  static const List<String> fontFamilyFallback = [
    'Noto Sans CJK SC',
    'Source Han Sans SC',
    'PingFang SC',
    'Hiragino Sans GB',
    'Microsoft YaHei',
    'sans-serif',
  ];

  static TextTheme _textTheme(TextTheme base) {
    return base.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );
  }

  static ThemeData light([Color seedColor = seed]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    // No fontFamily on ThemeData — Icons must keep MaterialIcons.
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(size: 24),
      primaryIconTheme: const IconThemeData(size: 24),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F6F3),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.68),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.65),
        elevation: 0,
        indicatorColor: seedColor.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor.withValues(alpha: 0.92),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  static ThemeData dark([Color seedColor = seed]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(size: 24),
      primaryIconTheme: const IconThemeData(size: 24),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1210),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        indicatorColor: seedColor.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }
}

/// Soft fade + slight horizontal slide for settings hub → subpages (and others).
class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Frosted glass container (毛玻璃).
class GlassSurface extends StatelessWidget {
  /// Set false in screenshot/golden tests — BackdropFilter+toImage can hang under flutter_test.
  static bool useFrostedBlur = true;

  /// Global blur strength multiplier (1.0 = default). Driven by settings.
  static double blurStrength = 1.0;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 18,
    this.padding,
    this.opacity,
    this.border = true,
    this.elevate = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double? opacity;
  final bool border;
  /// When false (e.g. full-bleed app bar), skip outer shadow.
  final bool elevate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Layering (MD3 soft frost / common Flutter glass pattern):
    // 1) tinted wash underneath (GlassScaffoldBackground)
    // 2) content cards: pure white translucent fill — never primaryContainer lerp
    // 3) chrome (GlassAppBar): lower opacity so it does not double-stack white
    // 4) shadow OUTSIDE ClipRRect so elevation is visible (clipping shadows = 两层白)
    final fill = Colors.white.withValues(
      alpha: opacity ?? (isDark ? 0.10 : 0.68),
    );
    // Light: soft dark hairline reads on soft gray-green wash; dark: light rim.
    final stroke = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);

    final radius = BorderRadius.circular(borderRadius);
    final surfaceDecoration = BoxDecoration(
      color: fill,
      borderRadius: radius,
      border: border ? Border.all(color: stroke, width: 1) : null,
    );
    final painted = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: surfaceDecoration,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    final effectiveBlur = blur * blurStrength;
    final frosted = ClipRRect(
      borderRadius: radius,
      child: useFrostedBlur && effectiveBlur > 0.5
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: painted,
            )
          : painted,
    );

    // Elevation lives outside the clip so soft shadows are not discarded.
    if (!elevate) return frosted;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
            blurRadius: isDark ? 22 : 14,
            offset: const Offset(0, 5),
            spreadRadius: isDark ? 0 : -0.5,
          ),
        ],
      ),
      child: frosted,
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: GlassSurface(
        borderRadius: 0,
        blur: 18,
        border: false,
        elevate: false,
        // Chrome: more translucent than content cards (avoids 两层白 with search).
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.28,
        child: const SizedBox.expand(),
      ),
    );
  }
}
