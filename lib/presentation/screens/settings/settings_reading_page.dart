import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../data/services/custom_font_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsReadingPage extends ConsumerStatefulWidget {
  const SettingsReadingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  ConsumerState<SettingsReadingPage> createState() =>
      _SettingsReadingPageState();
}

class _SettingsReadingPageState extends ConsumerState<SettingsReadingPage> {
  List<CustomFontInfo> _fonts = const [];

  @override
  void initState() {
    super.initState();
    _reloadFonts();
  }

  Future<void> _reloadFonts() async {
    final list = await ref.read(customFontServiceProvider).listFonts();
    if (mounted) setState(() => _fonts = list);
  }

  Future<void> _importFont() async {
    final strings = ref.read(stringsProvider);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ttf', 'otf'],
      );
      if (files.isEmpty) return;
      final path = files.first.path;
      if (path == null) return;
      final info = await ref.read(customFontServiceProvider).importFont(path);
      await _reloadFonts();
      await ref
          .read(settingsProvider.notifier)
          .saveSettings((c) => c.copyWith(customFontFamily: info.family));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.fontImported}: ${info.displayName}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.fontImportFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(16),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${strings.fontSize}: ${settings.fontSize.round()}'),
                Slider(
                  min: 12,
                  max: 36,
                  value: settings.fontSize.clamp(12, 36),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(fontSize: v)),
                ),
                Text(
                  '${strings.lineHeight}: ${settings.lineHeight.toStringAsFixed(2)}',
                ),
                Slider(
                  min: 1.2,
                  max: 2.4,
                  value: settings.lineHeight.clamp(1.2, 2.4),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(lineHeight: v)),
                ),
                Text(
                  '${strings.horizontalMargin}: ${settings.horizontalMargin.round()}',
                ),
                Slider(
                  min: 12,
                  max: 40,
                  value: settings.horizontalMargin.clamp(12, 40),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(horizontalMargin: v)),
                ),
                Text(
                  '${strings.paragraphSpacing}: ${settings.paragraphSpacing.round()}',
                ),
                Slider(
                  min: 4,
                  max: 32,
                  value: settings.paragraphSpacing.clamp(4, 32),
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(paragraphSpacing: v)),
                ),
                const SizedBox(height: 8),
                Text(strings.readingTheme),
                const SizedBox(height: 8),
                SegmentedButton<ReadingThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ReadingThemeMode.day,
                      label: Text(strings.day),
                    ),
                    ButtonSegment(
                      value: ReadingThemeMode.night,
                      label: Text(strings.night),
                    ),
                    ButtonSegment(
                      value: ReadingThemeMode.sepia,
                      label: Text(strings.sepia),
                    ),
                  ],
                  selected: {settings.readingTheme},
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(readingTheme: s.first)),
                ),
                const SizedBox(height: 16),
                Text(strings.pageTurn),
                const SizedBox(height: 8),
                SegmentedButton<PageTurnMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: PageTurnMode.scroll,
                      label: Text(strings.scrollMode),
                    ),
                    ButtonSegment(
                      value: PageTurnMode.paged,
                      label: Text(strings.pageMode),
                    ),
                  ],
                  selected: {settings.pageTurnMode},
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(pageTurnMode: s.first)),
                ),
                const SizedBox(height: 16),
                Text(strings.writingMode),
                const SizedBox(height: 8),
                SegmentedButton<WritingMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: WritingMode.horizontal,
                      label: Text(strings.writingHorizontal),
                    ),
                    ButtonSegment(
                      value: WritingMode.vertical,
                      label: Text(strings.writingVertical),
                    ),
                  ],
                  selected: {settings.writingMode},
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(writingMode: s.first)),
                ),
                const SizedBox(height: 16),
                Text(strings.readingFont),
                const SizedBox(height: 4),
                Text(
                  strings.importFontHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(strings.defaultFont),
                      selected:
                          settings.customFontFamily == null ||
                          settings.customFontFamily!.isEmpty,
                      onSelected: (_) => ref
                          .read(settingsProvider.notifier)
                          .saveSettings(
                            (c) => c.copyWith(clearCustomFont: true),
                          ),
                    ),
                    for (final f in _fonts)
                      InputChip(
                        label: Text(
                          f.displayName,
                          style: TextStyle(
                            fontFamily: f.family,
                            fontFamilyFallback: AppTheme.fontFamilyFallback,
                          ),
                        ),
                        selected: settings.customFontFamily == f.family,
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .saveSettings(
                              (c) => c.copyWith(customFontFamily: f.family),
                            ),
                        onDeleted: () async {
                          await ref
                              .read(customFontServiceProvider)
                              .deleteFont(f.family);
                          if (settings.customFontFamily == f.family) {
                            await ref
                                .read(settingsProvider.notifier)
                                .saveSettings(
                                  (c) => c.copyWith(clearCustomFont: true),
                                );
                          }
                          await _reloadFonts();
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.font_download_outlined,
                        size: 18,
                      ),
                      label: Text(strings.importFont),
                      onPressed: _importFont,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return body;
    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.settingsReading)),
        body: body,
      ),
    );
  }
}
