import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsPrivacyPage extends ConsumerWidget {
  const SettingsPrivacyPage({super.key, this.showAppBar = true});

  final bool showAppBar;

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
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: Text(strings.libraryPin),
                  subtitle: Text(strings.libraryPinSub),
                  value: settings.libraryPinEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(libraryPinEnabled: v)),
                ),
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(strings.exportNotesPath),
                  subtitle: Text(strings.exportNotesPathBody),
                ),
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text(strings.offlinePolicy),
                  subtitle: Text(
                    strings.isZh
                        ? '数据仅保存在本机，不会上传。'
                        : 'Data stays on this device and is never uploaded.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!showAppBar) return body;
    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.settingsPrivacy)),
        body: body,
      ),
    );
  }
}
