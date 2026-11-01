import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Material Design 3 themes with frosted-glass helpers and CJK-capable typography.
///
/// NotoSansSC is applied **only** via [textTheme] / [primaryTextTheme] / nav
/// [labelTextStyle]. Do **not** set [ThemeData.fontFamily] — that makes
/// [Icon] widgets inherit NotoSansSC and render Material Icons as tofu (□).
///
/// Dark surfaces are cool near-black neutrals (Harmonoid / MD3 frost), not the
/// muddy green-gray [ColorScheme.fromSeed] tends to paint when [seed] is green.
/// Primary stays seed-driven and is used as accent only.
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

  // ── Semantic neutrals (cool) — seed-independent canvas ──────────────────
  static const Color lightCanvas = Color(0xFFFAFBFC);
  static const Color lightCanvasMid = Color(0xFFF7F8FA);
  static const Color lightCanvasDeep = Color(0xFFF5F6F8);

  /// OLED true black — Now Playing / fullscreen music canvases.
  static const Color oledBlack = Color(0xFF000000);

  /// Near-true-black cool scaffold (OLED-friendly; cards use elevated containers).
  static const Color darkCanvas = Color(0xFF000000);
  static const Color darkSurfaceDim = Color(0xFF000000);
  static const Color darkSurfaceBright = Color(0xFF16191D);
  static const Color darkContainerLowest = Color(0xFF000000);
  static const Color darkContainerLow = Color(0xFF121518);
  static const Color darkContainer = Color(0xFF181B1F);
  static const Color darkContainerHigh = Color(0xFF1E2227);
  static const Color darkContainerHighest = Color(0xFF24292F);
  static const Color darkOnSurface = Color(0xFFE6E8EB);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B6BE);
  static const Color darkOutline = Color(0xFF8A9099);
  static const Color darkOutlineVariant = Color(0xFF3A3F46);

  static TextTheme _textTheme(TextTheme base) {
    return base.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
    );
  }

  static PageTransitionsTheme get _pageTransitions =>
      const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.iOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.linux: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.macOS: _SharedAxisPageTransitionsBuilder(),
          TargetPlatform.windows: _SharedAxisPageTransitionsBuilder(),
        },
      );

  /// Keep seed primary/secondary/tertiary; replace muddy dark surfaces.
  static ColorScheme _refineDarkScheme(ColorScheme seeded) {
    return seeded.copyWith(
      surface: darkCanvas,
      surfaceDim: darkSurfaceDim,
      surfaceBright: darkSurfaceBright,
      surfaceContainerLowest: darkContainerLowest,
      surfaceContainerLow: darkContainerLow,
      surfaceContainer: darkContainer,
      surfaceContainerHigh: darkContainerHigh,
      surfaceContainerHighest: darkContainerHighest,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      // Soften seed-tinted containers so frost cards stay neutral.
      primaryContainer:
          Color.lerp(darkContainerHigh, seeded.primary, 0.32)!,
      onPrimaryContainer:
          Color.lerp(darkOnSurface, seeded.primary, 0.12)!,
      secondaryContainer:
          Color.lerp(darkContainer, seeded.secondary, 0.22)!,
      onSecondaryContainer: darkOnSurface,
      tertiaryContainer:
          Color.lerp(darkContainer, seeded.tertiary, 0.20)!,
      onTertiaryContainer: darkOnSurface,
      // Inverse / chrome helpers used by snackbars etc.
      inverseSurface: darkContainerHighest,
      onInverseSurface: darkOnSurface,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  static ColorScheme _refineLightScheme(ColorScheme seeded) {
    return seeded.copyWith(
      surface: lightCanvas,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF3F4F6),
      surfaceContainer: const Color(0xFFEEEFF2),
      surfaceContainerHigh: const Color(0xFFE8EAED),
      surfaceContainerHighest: const Color(0xFFE2E4E8),
      // Soften green-mud containers from a green seed.
      primaryContainer:
          Color.lerp(const Color(0xFFE8F5E9), seeded.primaryContainer, 0.55)!,
      secondaryContainer:
          Color.lerp(const Color(0xFFF0F1F3), seeded.secondaryContainer, 0.45)!,
    );
  }

  static ThemeData light([Color seedColor = seed]) {
    final seeded = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final scheme = _refineLightScheme(seeded);
    // No fontFamily on ThemeData — Icons must keep MaterialIcons.
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: IconThemeData(size: 24, color: scheme.onSurface),
      primaryIconTheme: IconThemeData(size: 24, color: scheme.onPrimary),
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: lightCanvas,
      canvasColor: lightCanvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: seedColor.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 12,
            color: scheme.onSurface,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? seedColor
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor.withValues(alpha: 0.92),
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
        space: 1,
        thickness: 0.5,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: seedColor,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedColor: seedColor,
        selectedTileColor: seedColor.withValues(alpha: 0.10),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData dark([Color seedColor = seed]) {
    final seeded = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final scheme = _refineDarkScheme(seeded);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: _textTheme(base.textTheme.apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      )),
      primaryTextTheme: _textTheme(base.primaryTextTheme),
      iconTheme: const IconThemeData(size: 24, color: darkOnSurface),
      primaryIconTheme: IconThemeData(size: 24, color: scheme.onPrimary),
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: darkOnSurface,
        surfaceTintColor: Colors.transparent,
      ),
      scaffoldBackgroundColor: darkCanvas,
      canvasColor: darkCanvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Dense chrome over OLED black — readable tab labels, not a plastic sheet.
        backgroundColor: darkContainerLow.withValues(alpha: 0.94),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: seedColor.withValues(alpha: 0.26),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? darkOnSurface
                : darkOnSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? Color.lerp(darkOnSurface, seedColor, 0.35)!
                : darkOnSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color.lerp(seedColor, darkContainerHigh, 0.12)!
            .withValues(alpha: 0.95),
        foregroundColor: Colors.white,
        elevation: 1,
        focusElevation: 1,
        highlightElevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        backgroundColor: darkContainerHighest,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: darkOnSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: darkOutlineVariant.withValues(alpha: 0.7),
        space: 1,
        thickness: 0.5,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: seedColor,
        labelColor: darkOnSurface,
        unselectedLabelColor: darkOnSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: darkOnSurfaceVariant,
        textColor: darkOnSurface,
        selectedColor: Color.lerp(darkOnSurface, seedColor, 0.45)!,
        selectedTileColor: seedColor.withValues(alpha: 0.14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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

/// Opaque MD3 content surface — prefer for library cards, settings blocks, stats.
///
/// Glass stays on chrome ([GlassAppBar] / light frost bars). Content uses solid
/// [ColorScheme.surfaceContainer*] so type stays sharp on light and OLED black.
class SolidCard extends StatelessWidget {
  const SolidCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding,
    this.border = true,
    this.color,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool border;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final fill = color ??
        (isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest);
    final stroke = isDark
        ? cs.outlineVariant.withValues(alpha: 0.55)
        : cs.outlineVariant.withValues(alpha: 0.70);
    final radius = BorderRadius.circular(borderRadius);
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);

    return Material(
      color: fill,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border
            ? BorderSide(color: stroke, width: 0.75)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// Light frosted glass for chrome only (app bar / mini bar).
///
/// Prefer [SolidCard] for content cards — stacking translucent frost on a wash
/// reads as "plastic glass" and hurts text contrast.
class GlassSurface extends StatelessWidget {
  /// Set false in screenshot/golden tests — BackdropFilter+toImage can hang under flutter_test.
  static bool useFrostedBlur = true;

  /// Global blur strength multiplier (1.0 = default). Driven by settings.
  /// Product default is below 1.0 so first launch is not a full-screen smear.
  static double blurStrength = 0.55;

  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 14,
    this.padding,
    this.opacity,
    this.border = true,
    this.elevate = false,
    /// When true, skip BackdropFilter and paint a near-opaque fill (content cards).
    this.opaque = false,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double? opacity;
  final bool border;

  /// Kept for API compatibility. Soft drop shadows are removed (flat frost).
  final bool elevate;

  /// Near-solid surface — use for cards that must stay readable.
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    if (opaque) {
      return SolidCard(
        borderRadius: borderRadius,
        padding: padding,
        border: border,
        child: child,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Chrome frost: denser than old ultra-thin fills so bars stay legible.
    final fillAlpha = opacity ?? (isDark ? 0.14 : 0.22);
    final fill = Colors.white.withValues(alpha: fillAlpha.clamp(0.0, 1.0));
    final stroke = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.28);

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
        blur: 12,
        border: false,
        elevate: false,
        // Mild frost chrome — denser fill, weaker blur vs old full-bleed glass.
        opacity: isDark ? 0.10 : 0.16,
        child: const SizedBox.expand(),
      ),
    );
  }
}
