import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../domain/models/app_settings.dart';

class ReadingControlsSheet extends StatelessWidget {
  const ReadingControlsSheet({
    super.key,
    required this.strings,
    required this.settings,
    required this.onChanged,
    this.onAddBookmark,
    this.onAddNote,
  });

  final AppStrings strings;
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback? onAddBookmark;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(strings.readingTheme, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ReadingThemeMode>(
            segments: [
              ButtonSegment(value: ReadingThemeMode.day, label: Text(strings.day)),
              ButtonSegment(value: ReadingThemeMode.night, label: Text(strings.night)),
              ButtonSegment(value: ReadingThemeMode.sepia, label: Text(strings.sepia)),
            ],
            selected: {settings.readingTheme},
            onSelectionChanged: (s) =>
                onChanged(settings.copyWith(readingTheme: s.first)),
          ),
          const SizedBox(height: 16),
          Text('${strings.fontSize}: ${settings.fontSize.round()}'),
          Slider(
            min: 12,
            max: 36,
            value: settings.fontSize.clamp(12, 36),
            onChanged: (v) => onChanged(settings.copyWith(fontSize: v)),
          ),
          Text('${strings.lineHeight}: ${settings.lineHeight.toStringAsFixed(1)}'),
          Slider(
            min: 1.2,
            max: 2.4,
            value: settings.lineHeight.clamp(1.2, 2.4),
            onChanged: (v) => onChanged(settings.copyWith(lineHeight: v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onAddBookmark != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddBookmark,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(strings.addBookmark),
                  ),
                ),
              if (onAddBookmark != null && onAddNote != null)
                const SizedBox(width: 8),
              if (onAddNote != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(strings.addNote),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
