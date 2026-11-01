import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/glass_scaffold_bg.dart';
import '../reader/reader_router.dart';

const _comicFormats = {
  BookFormat.cbz,
  BookFormat.cbr,
};

/// Comic-focused library view (format filter) — NeoMedia Comic tab.
class ComicLibraryScreen extends ConsumerWidget {
  const ComicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final booksAsync = ref.watch(libraryProvider);
    final isZh = strings.isZh;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(isZh ? '漫画' : 'Comics'),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (books) {
            final comics = books
                .where((b) => _comicFormats.contains(b.format))
                .toList();
            if (comics.isEmpty) {
              return Center(
                child: Text(
                  isZh
                      ? '暂无漫画，请在「阅读」书库导入 CBZ / CBR'
                      : 'No comics yet — import CBZ / CBR from Books',
                ),
              );
            }
            return ListView.builder(
              itemCount: comics.length,
              itemBuilder: (context, i) {
                final book = comics[i];
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 64,
                    child: BookCover(book: book),
                  ),
                  title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(book.author),
                  onTap: () => openReader(context, book),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
