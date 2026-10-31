import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  String _fmt(int seconds, {required bool isZh}) {
    if (seconds < 60) return isZh ? '$seconds 秒' : '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return isZh ? '$m 分钟' : '${m}m';
    final h = m ~/ 60;
    final rm = m % 60;
    return isZh ? '$h 小时 $rm 分钟' : '${h}h ${rm}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final summary = ref.watch(statsSummaryProvider);
    final books = ref.watch(libraryProvider).value ?? [];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(strings.stats)),
        body: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (s) {
            final isZh = strings.isZh;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        strings.todayReading,
                        _fmt(s.todaySeconds, isZh: isZh),
                        Icons.today_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        strings.totalReading,
                        _fmt(s.totalSeconds, isZh: isZh),
                        Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        context,
                        strings.booksInProgress,
                        '${s.booksStarted}',
                        Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        context,
                        isZh ? '已读完' : 'Finished',
                        '${s.booksFinished}',
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassSurface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '各书阅读时长' : 'Time per book',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (s.perBookSeconds.isEmpty)
                        Text(isZh ? '暂无记录，打开一本书开始阅读即可累计。' : 'No sessions yet. Open a book to track time.')
                      else
                        ...s.perBookSeconds.entries.map((e) {
                          final matches = books.where((b) => b.id == e.key).toList();
                          final title = matches.isEmpty ? e.key : matches.first.title;
                          final book = matches.isEmpty ? null : matches.first;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: book == null
                                ? null
                                : LinearProgressIndicator(value: book.progress.clamp(0, 1)),
                            trailing: Text(_fmt(e.value, isZh: isZh)),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon) {
    return GlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
