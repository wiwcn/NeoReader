import 'package:flutter/material.dart';

import 'motion.dart';

/// Pill search field shared by Library and Music.
///
/// Shape / fill / focus ring come from [InputDecorationTheme]; this widget only
/// adds the MD3 affordances: search glyph, animated clear action and search
/// keyboard semantics.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final cs = Theme.of(context).colorScheme;
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: pill,
        enabledBorder: pill,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: cs.primary.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: AnimatedSwitcher(
          duration: reduce ? Duration.zero : AppMotion.instant,
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.emphasizedAccelerate,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: _controller.text.isEmpty
              ? const SizedBox(width: 44, height: 44)
              : IconButton(
                  key: const ValueKey('clear'),
                  onPressed: _clear,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
        ),
      ),
    );
  }
}
