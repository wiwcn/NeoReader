import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/annotation.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_scaffold_bg.dart';

class AnnotationsScreen extends ConsumerWidget {
  const AnnotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final async = ref.watch(allAnnotationsProvider);
    final books = ref.watch(libraryProvider).value ?? [];

    String bookTitle(String id) {
      for (final b in books) {
        if (b.id == id) return b.title;
      }
      return id;
    }

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(strings.annotations),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.exportLater)),
                );
              },
              child: Text(strings.exportLater),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            if (items.isEmpty) {
              return Center(child: Text(strings.noAnnotations));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = items[i];
                final icon = switch (a.type) {
                  AnnotationType.bookmark => Icons.bookmark_rounded,
                  AnnotationType.highlight => Icons.highlight_rounded,
                  AnnotationType.note => Icons.sticky_note_2_rounded,
                };
                return GlassSurface(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon),
                    title: Text(bookTitle(a.bookId), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [
                        a.type.name,
                        if (a.chapter != null) a.chapter!,
                        if (a.note != null) a.note!,
                        if (a.selectedText != null) a.selectedText!,
                        if (a.progress != null)
                          '${(a.progress! * 100).toStringAsFixed(0)}%',
                      ].join(' · '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(annotationRepositoryProvider).delete(a.id);
                        ref.invalidate(allAnnotationsProvider);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
