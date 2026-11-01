import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/models/app_settings.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsStatsPage extends ConsumerWidget {
  const SettingsStatsPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.resetStats),
        content: Text(strings.resetStatsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = await AppDatabase.instance.database;
    await db.delete('reading_sessions');
    ref.invalidate(statsSummaryProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.resetStatsDone)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SolidCard(
          padding: const EdgeInsets.all(8),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.timer_outlined),
                  title: Text(strings.showReadingDuration),
                  value: settings.showReadingDuration,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .saveSettings((c) => c.copyWith(showReadingDuration: v)),
                ),
                const Divider(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.restart_alt,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(strings.resetStats),
                  subtitle: Text(strings.dangerAction),
                  onTap: () => _reset(context, ref),
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
        appBar: GlassAppBar(title: Text(strings.settingsStats)),
        body: body,
      ),
    );
  }
}
