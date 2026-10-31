import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../reader/reader_router.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(filteredLibraryProvider);

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(strings.library),
          actions: [
            PopupMenuButton<BookSort>(
              tooltip: strings.sortBy,
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) =>
                  ref.read(librarySortProvider.notifier).state = v,
              itemBuilder: (_) => [
                PopupMenuItem(value: BookSort.added, child: Text(strings.sortAdded)),
                PopupMenuItem(value: BookSort.recent, child: Text(strings.sortRecent)),
                PopupMenuItem(value: BookSort.title, child: Text(strings.sortTitle)),
                PopupMenuItem(value: BookSort.author, child: Text(strings.sortAuthor)),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GlassSurface(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: strings.searchHint,
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) =>
                      ref.read(libraryQueryProvider.notifier).state = v,
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _import(context, ref, strings),
          icon: const Icon(Icons.add_rounded),
          label: Text(strings.importBook),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (books) {
            if (books.isEmpty) return EmptyLibrary(strings: strings);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: books.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final book = books[i];
                return GlassSurface(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => openReader(context, book),
                    onLongPress: () => _confirmDelete(context, ref, strings, book),
                    child: Row(
                      children: [
                        BookCover(book: book),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author.isEmpty
                                    ? strings.unknownAuthor
                                    : book.author,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: book.progress.clamp(0, 1),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(book.progress * 100).round()}%',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.format.name.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: strings.delete,
                          onPressed: () =>
                              _confirmDelete(context, ref, strings, book),
                        ),
                      ],
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

  Future<void> _import(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'epub', 'pdf', 'txt',
        // allow picking planned formats to show roadmap message
        'mobi', 'azw3', 'azw', 'fb2', 'cbz', 'cbr', 'md', 'docx', 'html', 'htm',
      ],
    );
    if (files.isEmpty) return;
    final import = ref.read(importServiceProvider);
    var ok = 0;
    String? lastError;
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      final r = await import.importFile(path);
      if (r.success) {
        ok++;
      } else {
        lastError = r.error;
      }
    }
    await ref.read(libraryProvider.notifier).refresh();
    if (!context.mounted) return;
    final msg = ok > 0
        ? '${strings.importSuccess} ×$ok'
        : (lastError?.startsWith('planned_or_unsupported') == true
            ? strings.unsupportedFormat
            : '${strings.importFailed}: $lastError');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    Book book,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final file = File(book.filePath);
      if (await file.exists()) await file.delete();
      if (book.coverPath != null) {
        final c = File(book.coverPath!);
        if (await c.exists()) await c.delete();
      }
    } catch (_) {}
    await ref.read(bookRepositoryProvider).delete(book.id);
    await ref.read(libraryProvider.notifier).refresh();
  }
}
