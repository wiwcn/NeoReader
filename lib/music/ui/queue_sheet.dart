import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../providers/music_providers.dart';

Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Opaque sheet — do not use transparent frost that shows page through.
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => const _QueueSheetBody(),
  );
}

class _QueueSheetBody extends ConsumerWidget {
  const _QueueSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final queue = ref.watch(playerQueueProvider).value ?? const <Track>[];
    final index = ref.watch(playerIndexProvider).value ?? 0;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ms.queue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: queue.isEmpty
                        ? null
                        : () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.clearQueue();
                            await ref.read(musicRepositoryProvider).saveQueue([], 0);
                          },
                    child: Text(ms.clearQueue),
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? Center(child: Text(ms.noQueue))
                  : ReorderableListView.builder(
                      padding: EdgeInsets.only(bottom: bottom + 8),
                      itemCount: queue.length,
                      onReorderItem: (oldIndex, newIndex) async {
                        final h = await ref.read(musicHandlerProvider.future);
                        await h.reorderQueue(oldIndex, newIndex);
                        await ref.read(musicRepositoryProvider).saveQueue(
                              h.tracks.map((t) => t.id).toList(),
                              h.currentIndex,
                            );
                      },
                      itemBuilder: (context, i) {
                        final t = queue[i];
                        final selected = i == index;
                        return ListTile(
                          key: ValueKey(t.id),
                          selected: selected,
                          leading: Icon(
                            selected
                                ? Icons.graphic_eq_rounded
                                : Icons.drag_handle_rounded,
                          ),
                          title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            t.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.playTrackAt(i);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
