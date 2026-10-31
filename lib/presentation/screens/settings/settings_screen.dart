import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_theme.dart';
import '../../../data/parsers/format_registry.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.settings)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: Text(strings.language),
                    subtitle: Text(settings.isZh ? '中文' : 'English'),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'zh', label: Text('中文')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {settings.isZh ? 'zh' : 'en'},
                      onSelectionChanged: (s) {
                        ref.read(settingsProvider.notifier).saveSettings(
                              (cur) => cur.copyWith(localeCode: s.first),
                            );
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(strings.theme),
                    subtitle: Text(switch (settings.themeMode) {
                      AppThemeModePref.system => strings.themeSystem,
                      AppThemeModePref.light => strings.themeLight,
                      AppThemeModePref.dark => strings.themeDark,
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: SegmentedButton<AppThemeModePref>(
                      segments: [
                        ButtonSegment(value: AppThemeModePref.system, label: Text(strings.themeSystem)),
                        ButtonSegment(value: AppThemeModePref.light, label: Text(strings.themeLight)),
                        ButtonSegment(value: AppThemeModePref.dark, label: Text(strings.themeDark)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) {
                        ref.read(settingsProvider.notifier).saveSettings(
                              (cur) => cur.copyWith(themeMode: s.first),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.readingDefaults, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                  Text(strings.readingTheme),
                  const SizedBox(height: 8),
                  SegmentedButton<ReadingThemeMode>(
                    segments: [
                      ButtonSegment(value: ReadingThemeMode.day, label: Text(strings.day)),
                      ButtonSegment(value: ReadingThemeMode.night, label: Text(strings.night)),
                      ButtonSegment(value: ReadingThemeMode.sepia, label: Text(strings.sepia)),
                    ],
                    selected: {settings.readingTheme},
                    onSelectionChanged: (s) => ref.read(settingsProvider.notifier).saveSettings(
                          (c) => c.copyWith(readingTheme: s.first),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.features, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(strings.offlinePolicy, style: Theme.of(context).textTheme.bodySmall),
                  const Divider(height: 24),
                  ...FormatRegistry.plannedModules.entries.map(
                    (e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.construction_rounded, size: 20),
                      title: Text(e.value),
                      subtitle: Text(strings.comingSoon),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.about, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(strings.aboutBody),
                  const SizedBox(height: 8),
                  Text('NeoReader v1.0.0 · AGPL-3.0', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
