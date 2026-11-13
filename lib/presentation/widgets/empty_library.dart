import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import 'app_empty_state.dart';

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({
    super.key,
    required this.strings,
    this.onImport,
  });

  final AppStrings strings;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.auto_stories_rounded,
      title: strings.emptyLibrary,
      message: strings.offlinePolicy,
      actionLabel: onImport == null ? null : strings.importBook,
      actionIcon: Icons.add_rounded,
      onAction: onImport,
    );
  }
}
