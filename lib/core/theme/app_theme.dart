import 'dart:ui';

import 'package:animations/animations.dart';
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
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(size: 24),
      primaryIconTheme: const IconThemeData(size: 24),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.iOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.linux: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.macOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.windows: _SharedAxisPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFBFC),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.10),
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
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(size: 24),
      primaryIconTheme: const IconThemeData(size: 24),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.iOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.linux: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.macOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.windows: _SharedAxisPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1113),
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

/// MD3 shared-axis horizontal page transitions ([animations] package).
///
/// Transparent fill keeps the glass scaffold wash visible during the transition.
class _SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SharedAxisPageTransitionsBuilder();

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
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// Flat MD3 frosted glass (毛玻璃) — blur + low-alpha frost + thin rim.
///
/// Pattern mirrors common Flutter glass kits (ClipRRect → BackdropFilter →
/// frost fill ~0.1 → thin white border). No BoxShadow / plastic elevation.
class GlassSurface extends StatelessWidget {
  /// Set false in screenshot/golden tests — BackdropFilter+toImage can hang under flutter_test.
  static bool useFrostedBlur = true;

  /// Global blur strength multiplier (1.0 = default). Driven by settings.
  static double blurStrength = 1.0;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
    this.opacity,
    this.border = true,
    this.elevate = false,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double? opacity;
  final bool border;

  /// Kept for API compatibility. Soft drop shadows are removed (flat frost).
  final bool elevate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Content cards: low frost so BackdropFilter reads against the wash.
    // Chrome/AppBar should pass a lower [opacity] (~0.06–0.10).
    final fillAlpha = opacity ?? (isDark ? 0.10 : 0.14);
    final fill = Colors.white.withValues(alpha: fillAlpha.clamp(0.0, 1.0));
    // Light white rim (not dark hairline) — reads as glass edge on tinted wash.
    final stroke = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.30);

    final radius = BorderRadius.circular(borderRadius);
    final effectiveBlur = blur * blurStrength;
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    Widget frost = Stack(
      fit: StackFit.passthrough,
      children: [
        if (useFrostedBlur && effectiveBlur > 0.5)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
        ),
        content,
      ],
    );

    frost = ClipRRect(
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: frost,
    );

    if (border) {
      frost = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: stroke, width: 0.75),
        ),
        child: frost,
      );
    }

    // [elevate] is intentionally a no-op — flat MD3 frost, no soft shadows.
    return frost;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: GlassSurface(
        borderRadius: 0,
        blur: 20,
        border: false,
        elevate: false,
        // Chrome: lower than content cards so it does not double-stack frost.
        opacity: isDark ? 0.06 : 0.08,
        child: const SizedBox.expand(),
      ),
    );
  }
}
