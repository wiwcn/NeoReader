import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Product motion tokens (Refero craft / MD3 product UI).
///
/// | Category   | Duration   | Use                          |
/// | Instant    | 90–150ms   | press / hover                |
/// | State      | 160–240ms  | tab fade, progress, stagger  |
/// | Page       | 240–360ms  | route / shared-axis         |
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration state = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 280);
  static const Duration pageReverse = Duration(milliseconds: 240);
  static const Duration staggerItem = Duration(milliseconds: 200);
  static const Duration staggerDelay = Duration(milliseconds: 28);
  static const Duration progress = Duration(milliseconds: 220);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
}

/// Thin wrapper around [flutter_staggered_animations] for one import site.
///
/// Call sites wrap the [ListView] with [AnimationLimiter] (or use
/// [staggeredListView]) and each row with [StaggeredFadeSlide].
class StaggeredFadeSlide extends StatelessWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = AppMotion.staggerDelay,
    this.duration = AppMotion.staggerItem,
    this.verticalOffset = 10.0,
  });

  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;
  final double verticalOffset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      delay: baseDelay,
      child: SlideAnimation(
        verticalOffset: verticalOffset,
        curve: AppMotion.enter,
        child: FadeInAnimation(
          curve: AppMotion.enter,
          child: child,
        ),
      ),
    );
  }
}

/// Wraps a scrollable list body so staggered children animate on first paint.
Widget staggeredListView({
  required BuildContext context,
  required Widget listView,
}) {
  if (MediaQuery.disableAnimationsOf(context)) return listView;
  return AnimationLimiter(child: listView);
}

/// Animated reading progress bar that eases to [value].
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.minHeight = 6,
  });

  final double value;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    if (MediaQuery.disableAnimationsOf(context)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: target, minHeight: minHeight),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: AppMotion.progress,
      curve: AppMotion.enter,
      builder: (context, v, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: v, minHeight: minHeight),
        );
      },
    );
  }
}

/// Light press scale for FAB / tappable controls.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.pressedScale = 0.94});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Listener avoids competing with the child button in the gesture arena.
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: reduce ? Duration.zero : AppMotion.instant,
        curve: AppMotion.press,
        child: widget.child,
      ),
    );
  }
}

/// Bottom-nav body switcher: true [IndexedStack] + fade so tabs stay alive.
class FadeIndexedStack extends StatelessWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppMotion.state,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  /// Keep every tab mounted (true IndexedStack) so music playback UI / scroll
  /// position survive tab switches; fade the active child for MD3 motion.
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _FadeKeepAlive(
            key: ValueKey<int>(i),
            visible: i == index,
            duration: reduce ? Duration.zero : duration,
            child: children[i],
          ),
      ],
    );
  }
}

class _FadeKeepAlive extends StatelessWidget {
  const _FadeKeepAlive({
    super.key,
    required this.visible,
    required this.duration,
    required this.child,
  });

  final bool visible;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: AppMotion.enter,
        child: TickerMode(
          enabled: visible,
          child: child,
        ),
      ),
    );
  }
}

/// Shared-axis horizontal [PageRoute] for hub → detail pushes (MD3).
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required WidgetBuilder builder,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          transitionDuration: AppMotion.page,
          reverseTransitionDuration: AppMotion.pageReverse,
        );
}
