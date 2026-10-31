import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../../widgets/motion.dart';
import '../reader/reader_router.dart';

/// Glass details / edit page for a library book.
class BookDetailsPage extends ConsumerStatefulWidget {
  const BookDetailsPage({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends ConsumerState<BookDetailsPage> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Book? _book;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _tagsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final book = await ref.read(bookRepositoryProvider).getById(widget.bookId);
    if (!mounted) return;
    setState(() {
      _book = book;
      _loading = false;
      if (book != null) {
        _titleCtrl.text = book.title;
        _authorCtrl.text = book.author;
        _tagsCtrl.text = book.tags.join(', ');
        _descCtrl.text = book.description;
      }
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final book = _book;
    if (book == null || _saving) return;
    final strings = ref.read(stringsProvider);
    setState(() => _saving = true);
    final tags = Book.decodeTags(_tagsCtrl.text.replaceAll('，', ','));
    final updated = book.copyWith(
      title: _titleCtrl.text.trim().isEmpty
          ? book.title
          : _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      tags: tags,
    );
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    setState(() {
      _book = updated;
      _dirty = false;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.saved)),
    );
  }

  Future<void> _changeCover() async {
    final book = _book;
    if (book == null) return;
    final strings = ref.read(stringsProvider);
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return;
    final srcPath = files.first.path;
    if (srcPath == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docs.path, AppConstants.coversDirName));
    if (!await coversDir.exists()) await coversDir.create(recursive: true);
    final ext = p.extension(srcPath).toLowerCase();
    final safeExt =
        (ext == '.png' || ext == '.webp' || ext == '.gif') ? ext : '.jpg';
    final dest = p.join(coversDir.path, '${book.id}$safeExt');
    await File(srcPath).copy(dest);
    // Remove previous cover if path differs.
    if (book.coverPath != null && book.coverPath != dest) {
      try {
        final old = File(book.coverPath!);
        if (await old.exists()) await old.delete();
      } catch (_) {}
    }
    final updated = book.copyWith(coverPath: dest);
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _book = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.coverUpdated)),
    );
  }

  Future<void> _removeCover() async {
    final book = _book;
    if (book == null || book.coverPath == null) return;
    final strings = ref.read(stringsProvider);
    try {
      final f = File(book.coverPath!);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    final updated = book.copyWith(coverPath: null);
    await ref.read(bookRepositoryProvider).upsert(updated);
    await ref.read(libraryProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _book = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.coverRemoved)),
    );
  }

  Future<void> _confirmDelete() async {
    final book = _book;
    if (book == null) return;
    final strings = ref.read(stringsProvider);
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
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(strings.bookDetails),
          actions: [
            if (_dirty)
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(strings.save),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _book == null
                ? Center(child: Text(strings.importFailed))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      GlassSurface(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            BookCover(
                              book: _book!,
                              width: 120,
                              height: 160,
                              borderRadius: 14,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _changeCover,
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(strings.changeCover),
                                ),
                                if (_book!.coverPath != null)
                                  OutlinedButton.icon(
                                    onPressed: _removeCover,
                                    icon: const Icon(Icons.hide_image_outlined),
                                    label: Text(strings.removeCover),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${strings.formatLabel}: ${_book!.format.name.toUpperCase()}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: AnimatedProgressBar(
                                    value: _book!.progress,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(_book!.progress * 100).round()}%',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GlassSurface(
                        borderRadius: 18,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                labelText: strings.bookTitle,
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _markDirty(),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _authorCtrl,
                              decoration: InputDecoration(
                                labelText: strings.bookAuthor,
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _markDirty(),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tagsCtrl,
                              decoration: InputDecoration(
                                labelText: strings.bookTags,
                                hintText: strings.bookTagsHint,
                              ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _markDirty(),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descCtrl,
                              decoration: InputDecoration(
                                labelText: strings.bookDescription,
                                hintText: strings.bookDescriptionHint,
                                alignLabelWithHint: true,
                              ),
                              minLines: 3,
                              maxLines: 6,
                              onChanged: (_) => _markDirty(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => openReader(context, _book!),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: Text(strings.openBook),
                      ),
                      const SizedBox(height: 10),
                      if (_dirty)
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(strings.save),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        strings.dangerAction,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                        ),
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(strings.delete),
                      ),
                    ],
                  ),
      ),
    );
  }
}
