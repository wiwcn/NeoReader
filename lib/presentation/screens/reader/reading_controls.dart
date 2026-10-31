import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../data/services/custom_font_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../../core/theme/app_theme.dart';

class ReadingControlsSheet extends StatelessWidget {
  const ReadingControlsSheet({
    super.key,
    required this.strings,
    required this.settings,
    required this.onChanged,
    this.customFonts = const [],
    this.onImportFont,
    this.onDeleteFont,
    this.onAddBookmark,
    this.onAddNote,
  });

  final AppStrings strings;
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final List<CustomFontInfo> customFonts;
  final VoidCallback? onImportFont;
  final ValueChanged<String>? onDeleteFont;
  final VoidCallback? onAddBookmark;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
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
            Text(strings.readingTheme,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ReadingThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: ReadingThemeMode.day, label: Text(strings.day)),
                ButtonSegment(
                    value: ReadingThemeMode.night, label: Text(strings.night)),
                ButtonSegment(
                    value: ReadingThemeMode.sepia, label: Text(strings.sepia)),
              ],
              selected: {settings.readingTheme},
              onSelectionChanged: (s) =>
                  onChanged(settings.copyWith(readingTheme: s.first)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  tooltip: strings.decreaseFont,
                  onPressed: () => onChanged(settings.copyWith(
                    fontSize: (settings.fontSize - 1).clamp(12, 36),
                  )),
                  icon: const Icon(Icons.text_decrease_rounded),
                ),
                Expanded(
                  child: Text(
                    '${strings.fontSize}: ${settings.fontSize.round()}',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: strings.increaseFont,
                  onPressed: () => onChanged(settings.copyWith(
                    fontSize: (settings.fontSize + 1).clamp(12, 36),
                  )),
                  icon: const Icon(Icons.text_increase_rounded),
                ),
              ],
            ),
            Slider(
              min: 12,
              max: 36,
              value: settings.fontSize.clamp(12, 36),
              onChanged: (v) => onChanged(settings.copyWith(fontSize: v)),
            ),
            Text(
                '${strings.lineHeight}: ${settings.lineHeight.toStringAsFixed(2)}'),
            Slider(
              min: 1.2,
              max: 2.4,
              value: settings.lineHeight.clamp(1.2, 2.4),
              onChanged: (v) => onChanged(settings.copyWith(lineHeight: v)),
            ),
            Text(
                '${strings.horizontalMargin}: ${settings.horizontalMargin.round()}'),
            Slider(
              min: 12,
              max: 40,
              value: settings.horizontalMargin.clamp(12, 40),
              onChanged: (v) =>
                  onChanged(settings.copyWith(horizontalMargin: v)),
            ),
            const SizedBox(height: 8),
            Text(strings.pageTurn),
            const SizedBox(height: 8),
            SegmentedButton<PageTurnMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: PageTurnMode.scroll,
                    label: Text(strings.scrollMode)),
                ButtonSegment(
                    value: PageTurnMode.paged, label: Text(strings.pageMode)),
              ],
              selected: {settings.pageTurnMode},
              onSelectionChanged: (s) =>
                  onChanged(settings.copyWith(pageTurnMode: s.first)),
            ),
            const SizedBox(height: 16),
            Text(strings.writingMode),
            const SizedBox(height: 8),
            SegmentedButton<WritingMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: WritingMode.horizontal,
                    label: Text(strings.writingHorizontal)),
                ButtonSegment(
                    value: WritingMode.vertical,
                    label: Text(strings.writingVertical)),
              ],
              selected: {settings.writingMode},
              onSelectionChanged: (s) =>
                  onChanged(settings.copyWith(writingMode: s.first)),
            ),
            const SizedBox(height: 16),
            Text(strings.readingFont),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(strings.defaultFont),
                  selected: settings.customFontFamily == null ||
                      settings.customFontFamily!.isEmpty,
                  onSelected: (_) => onChanged(
                    settings.copyWith(clearCustomFont: true),
                  ),
                ),
                for (final f in customFonts)
                  InputChip(
                    label: Text(f.displayName),
                    selected: settings.customFontFamily == f.family,
                    onPressed: () => onChanged(
                      settings.copyWith(customFontFamily: f.family),
                    ),
                    onDeleted: onDeleteFont == null
                        ? null
                        : () => onDeleteFont!(f.family),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                if (onImportFont != null)
                  ActionChip(
                    avatar: const Icon(Icons.font_download_outlined, size: 18),
                    label: Text(strings.importFont),
                    onPressed: onImportFont,
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }
}
