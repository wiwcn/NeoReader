import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/empty_library.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';
import 'book_details_page.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// Shared cover size / left edge across list book cards.
  static const double _coverW = 52;
  static const double _coverH = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(filteredLibraryProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final layout = settings.libraryLayout;
    final cs = Theme.of(context).colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: GlassAppBar(
          title: Text(strings.library),
          actions: [
            IconButton(
              tooltip: layout == LibraryLayout.grid
                  ? strings.layoutList
                  : strings.layoutGrid,
              icon: Icon(
                layout == LibraryLayout.grid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: () {
                final next = layout == LibraryLayout.grid
                    ? LibraryLayout.list
                    : LibraryLayout.grid;
                ref
                    .read(settingsProvider.notifier)
                    .saveSettings((c) => c.copyWith(libraryLayout: next));
              },
            ),
            PopupMenuButton<BookSort>(
              tooltip: strings.sortBy,
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) =>
                  ref.read(librarySortProvider.notifier).state = v,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: BookSort.added,
                  child: Text(strings.sortAdded),
                ),
                PopupMenuItem(
                  value: BookSort.recent,
                  child: Text(strings.sortRecent),
                ),
                PopupMenuItem(
                  value: BookSort.title,
                  child: Text(strings.sortTitle),
                ),
                PopupMenuItem(
                  value: BookSort.author,
                  child: Text(strings.sortAuthor),
                ),
              ],
            ),
          ],
          // Search lives in chrome — filled pill, NOT a second GlassSurface.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: strings.searchHint,
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface.withValues(alpha: 0.45),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(libraryQueryProvider.notifier).state = v,
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
            if (books.isEmpty) {
              return EmptyLibrary(
                strings: strings,
                onImport: () => _import(context, ref, strings),
              );
            }
            if (layout == LibraryLayout.grid) {
              return _buildGrid(context, ref, strings, books);
            }
            return _buildList(context, ref, strings, books);
          },
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    List<Book> books,
  ) {
    return staggeredListView(
      context: context,
      listView: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 112),
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final book = books[i];
          return StaggeredFadeSlide(
            index: i,
            child: PressScale(
              pressedScale: 0.98,
              child: _BookGlassCard(
                book: book,
                strings: strings,
                coverW: _coverW,
                coverH: _coverH,
                onOpen: () => openReader(context, book),
                onDetails: () => _openDetails(context, book),
                onDelete: () => _confirmDelete(context, ref, strings, book),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
    List<Book> books,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 3 : 2;
    return staggeredListView(
      context: context,
      listView: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 112),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: books.length,
        itemBuilder: (context, i) {
          final book = books[i];
          return StaggeredFadeSlide(
            index: i,
            child: PressScale(
              pressedScale: 0.97,
              child: _BookGridCard(
                book: book,
                strings: strings,
                onOpen: () => openReader(context, book),
                onDetails: () => _openDetails(context, book),
                onDelete: () => _confirmDelete(context, ref, strings, book),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, Book book) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailsPage(bookId: book.id),
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

Future<void> _showBookMenu(
  BuildContext context, {
  required AppStrings strings,
  required VoidCallback onDetails,
  required VoidCallback onDelete,
  required RelativeRect position,
}) async {
  final selected = await showMenu<String>(
    context: context,
    position: position,
    items: [
      PopupMenuItem(value: 'details', child: Text(strings.bookDetails)),
      PopupMenuItem(value: 'edit', child: Text(strings.editBook)),
      PopupMenuItem(value: 'delete', child: Text(strings.delete)),
    ],
  );
  if (selected == 'details' || selected == 'edit') onDetails();
  if (selected == 'delete') onDelete();
}

RelativeRect _menuPositionFrom(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) {
    return const RelativeRect.fromLTRB(100, 100, 100, 100);
  }
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  return RelativeRect.fromRect(
    Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height),
    Offset.zero & overlay.size,
  );
}

/// One translucent glass card per book — list mode.
class _BookGlassCard extends StatelessWidget {
  const _BookGlassCard({
    required this.book,
    required this.strings,
    required this.coverW,
    required this.coverH,
    required this.onOpen,
    required this.onDetails,
    required this.onDelete,
  });

  final Book book;
  final AppStrings strings;
  final double coverW;
  final double coverH;
  final VoidCallback onOpen;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final author = book.author.isEmpty ? strings.unknownAuthor : book.author;
    final pct = '${(book.progress * 100).round()}%';

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          onLongPress: () => _showBookMenu(
            context,
            strings: strings,
            onDetails: onDetails,
            onDelete: onDelete,
            position: _menuPositionFrom(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BookCover(
                book: book,
                width: coverW,
                height: coverH,
                borderRadius: 10,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.format.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar with trailing % label (no separate column).
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedProgressBar(
                            value: book.progress,
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pct,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: strings.moreActions,
                icon: const Icon(Icons.more_vert_rounded, size: 22),
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'details' || v == 'edit') onDetails();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Text(strings.bookDetails),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(strings.editBook),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(strings.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookGridCard extends StatelessWidget {
  const _BookGridCard({
    required this.book,
    required this.strings,
    required this.onOpen,
    required this.onDetails,
    required this.onDelete,
  });

  final Book book;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = '${(book.progress * 100).round()}%';

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          onLongPress: () => _showBookMenu(
            context,
            strings: strings,
            onDetails: onDetails,
            onDelete: onDelete,
            position: _menuPositionFrom(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: BookCover(
                            book: book,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            borderRadius: 12,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: cs.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            child: PopupMenuButton<String>(
                              tooltip: strings.moreActions,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: cs.onSurface,
                              ),
                              onSelected: (v) {
                                if (v == 'details' || v == 'edit') onDetails();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'details',
                                  child: Text(strings.bookDetails),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(strings.editBook),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(strings.delete),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      value: book.progress,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    pct,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
