import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  static const double _coverW = 56;
  static const double _coverH = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(filteredLibraryProvider);

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: GlassSurface(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: strings.searchHint,
                    border: InputBorder.none,
                    isDense: true,
                    icon: const Icon(Icons.search_rounded, size: 22),
                  ),
                  onChanged: (v) =>
                      ref.read(libraryQueryProvider.notifier).state = v,
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: PressScale(
          child: FloatingActionButton.extended(
            onPressed: () => _import(context, ref, strings),
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.importBook),
          ),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (books) {
            if (books.isEmpty) return EmptyLibrary(strings: strings);
            return ListView.separated(
              // Extra bottom padding so last card clears FAB + nav bar.
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              itemCount: books.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final book = books[i];
                return StaggeredFadeSlide(
                  index: i,
                  child: GlassSurface(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => openReader(context, book),
                      onLongPress: () =>
                          _confirmDelete(context, ref, strings, book),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BookCover(
                            book: book,
                            width: _coverW,
                            height: _coverH,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  book.author.isEmpty
                                      ? strings.unknownAuthor
                                      : book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedProgressBar(
                                        value: book.progress,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(book.progress * 100).round()}%',
                                      style:
                                          Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.format.name.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: strings.delete,
                            onPressed: () =>
                                _confirmDelete(context, ref, strings, book),
                          ),
                        ],
                      ),
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
      allowedExtensions: AppConstants.importPickerExtensions,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
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
