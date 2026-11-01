import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Thin wrapper around [flutter_staggered_animations] for one import site.
///
/// Call sites wrap the [ListView] with [AnimationLimiter] (or use
/// [staggeredListView]) and each row with [StaggeredFadeSlide].
class StaggeredFadeSlide extends StatelessWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 320),
    this.verticalOffset = 12.0,
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
        child: FadeInAnimation(child: child),
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
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
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
        duration: reduce ? Duration.zero : const Duration(milliseconds: 100),
        curve: Curves.easeOut,
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
    this.duration = const Duration(milliseconds: 220),
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
        curve: Curves.easeOutCubic,
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
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}
