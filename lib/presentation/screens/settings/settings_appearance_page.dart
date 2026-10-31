import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsAppearancePage extends ConsumerWidget {
  const SettingsAppearancePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  static const _seeds = <int>[
    0xFF2E7D32,
    0xFF1565C0,
    0xFF6A1B9A,
    0xFFC62828,
    0xFFEF6C00,
    0xFF00838F,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(strings.language),
                subtitle: Text(settings.isZh ? '中文' : 'English'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
              const Divider(height: 8),
              ListTile(
                title: Text(strings.theme),
                subtitle: Text(switch (settings.themeMode) {
                  AppThemeModePref.system => strings.themeSystem,
                  AppThemeModePref.light => strings.themeLight,
                  AppThemeModePref.dark => strings.themeDark,
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SegmentedButton<AppThemeModePref>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: [
                        ButtonSegment(
                          value: AppThemeModePref.system,
                          label: Text(strings.themeSystem, overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: AppThemeModePref.light,
                          label: Text(strings.themeLight, overflow: TextOverflow.ellipsis),
                        ),
                        ButtonSegment(
                          value: AppThemeModePref.dark,
                          label: Text(strings.themeDark, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) {
                        ref.read(settingsProvider.notifier).saveSettings(
                              (cur) => cur.copyWith(themeMode: s.first),
                            );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 8),
              ListTile(title: Text(strings.seedColor)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in _seeds)
                      GestureDetector(
                        onTap: () => ref.read(settingsProvider.notifier).saveSettings(
                              (cur) => cur.copyWith(seedColorValue: c),
                            ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: settings.seedColorValue == c
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                title: Text(strings.glassBlur),
                subtitle: Text('${(settings.glassBlur * 100).round()}%'),
              ),
              Slider(
                min: 0,
                max: 2,
                divisions: 20,
                value: settings.glassBlur.clamp(0, 2),
                onChanged: (v) {
                  GlassSurface.blurStrength = v;
                  ref.read(settingsProvider.notifier).saveSettings(
                        (cur) => cur.copyWith(glassBlur: v),
                      );
                },
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
        appBar: GlassAppBar(title: Text(strings.settingsAppearance)),
        body: body,
      ),
    );
  }
}
