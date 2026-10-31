import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsLibraryPage extends ConsumerWidget {
  const SettingsLibraryPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clearCache),
        content: Text(strings.clearCacheConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.confirm)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final cache = Directory(p.join(docs.path, 'cache'));
      if (await cache.exists()) {
        await cache.delete(recursive: true);
      }
      // Keep covers that belong to books; only wipe a dedicated temp dir if present.
      final tmp = Directory(p.join(docs.path, 'tmp'));
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.clearCacheDone)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    String sortLabel(BookSort s) => switch (s) {
          BookSort.title => strings.sortTitle,
          BookSort.author => strings.sortAuthor,
          BookSort.recent => strings.sortRecent,
          BookSort.added => strings.sortAdded,
        };

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
            children: [
              ListTile(
                title: Text(strings.defaultSort),
                subtitle: Text(sortLabel(settings.defaultSort)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in BookSort.values)
                      ChoiceChip(
                        label: Text(sortLabel(s)),
                        selected: settings.defaultSort == s,
                        onSelected: (_) {
                          ref.read(settingsProvider.notifier).saveSettings(
                                (c) => c.copyWith(defaultSort: s),
                              );
                          ref.read(librarySortProvider.notifier).state = s;
                        },
                      ),
                  ],
                ),
              ),
            ],
          )),
        ),
        const SizedBox(height: 12),
        GlassSurface(
          padding: const EdgeInsets.all(16),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.importFormats, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(strings.importFormatsBody),
              const SizedBox(height: 8),
              Text(
                AppConstants.importPickerExtensions.map((e) => '.$e').join('  '),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          )),
        ),
        const SizedBox(height: 12),
        Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(strings.clearCache),
            subtitle: Text(strings.dangerAction),
            onTap: () => _clearCache(context, ref),
          ),
        ),
      ],
    );

    if (!showAppBar) return body;
    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.settingsLibrary)),
        body: body,
      ),
    );
  }
}
