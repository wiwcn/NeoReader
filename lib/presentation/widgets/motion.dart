import 'package:flutter/material.dart';

/// Staggered fade + slight upward slide for list cards.
class StaggeredFadeSlide extends StatelessWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delayMs = (baseDelay.inMilliseconds * index).clamp(0, 280);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Interval(
        delayMs / (duration.inMilliseconds + delayMs).clamp(1, 9999),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
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
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.94,
  });

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

/// Fade when switching bottom-nav tabs (keeps each child keyed).
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

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      layoutBuilder: (current, previous) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previous,
            ?current,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: children[index],
      ),
    );
  }
}
