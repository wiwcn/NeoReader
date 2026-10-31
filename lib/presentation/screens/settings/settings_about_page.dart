import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class SettingsAboutPage extends ConsumerWidget {
  const SettingsAboutPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  static const _repo = 'https://github.com/wiwcn/NeoReader';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

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
              Text(strings.about, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(strings.aboutBody),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag),
                title: Text(strings.versionLabel),
                subtitle: const Text('NeoReader v1.0.0'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: Text(strings.license),
                subtitle: const Text('GPL-3.0'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite_outline),
                title: Text(strings.thanksKoodo),
                subtitle: Text(strings.thanksKoodoBody),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.code),
                title: Text(strings.openSourceRepo),
                subtitle: const Text(_repo),
                onTap: () async {
                  await Clipboard.setData(const ClipboardData(text: _repo));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.isZh ? '仓库链接已复制' : 'Repository URL copied',
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(strings.offlinePolicy, style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
        ),
      ],
    );

    if (!showAppBar) return body;
    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.about)),
        body: body,
      ),
    );
  }
}
