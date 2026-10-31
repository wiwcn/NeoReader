import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsReadingPage extends ConsumerWidget {
  const SettingsReadingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onChanged: (v) => ref.read(settingsProvider.notifier).saveSettings(
                      (c) => c.copyWith(fontSize: v),
                    ),
              ),
              Text('${strings.lineHeight}: ${settings.lineHeight.toStringAsFixed(1)}'),
              Slider(
                min: 1.2,
                max: 2.4,
                value: settings.lineHeight.clamp(1.2, 2.4),
                onChanged: (v) => ref.read(settingsProvider.notifier).saveSettings(
                      (c) => c.copyWith(lineHeight: v),
                    ),
              ),
              const SizedBox(height: 8),
              Text(strings.readingTheme),
              const SizedBox(height: 8),
              SegmentedButton<ReadingThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: ReadingThemeMode.day, label: Text(strings.day)),
                  ButtonSegment(value: ReadingThemeMode.night, label: Text(strings.night)),
                  ButtonSegment(value: ReadingThemeMode.sepia, label: Text(strings.sepia)),
                ],
                selected: {settings.readingTheme},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).saveSettings(
                          (c) => c.copyWith(readingTheme: s.first),
                        ),
              ),
              const SizedBox(height: 16),
              Text(strings.pageTurn),
              const SizedBox(height: 8),
              SegmentedButton<PageTurnMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: PageTurnMode.scroll, label: Text(strings.scrollMode)),
                  ButtonSegment(value: PageTurnMode.paged, label: Text(strings.pageMode)),
                ],
                selected: {settings.pageTurnMode},
                onSelectionChanged: (s) =>
                    ref.read(settingsProvider.notifier).saveSettings(
                          (c) => c.copyWith(pageTurnMode: s.first),
                        ),
              ),
            ],
          )),
        ),
      ],
    );

    if (!showAppBar) return body;
    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.settingsReading)),
        body: body,
      ),
    );
  }
}
