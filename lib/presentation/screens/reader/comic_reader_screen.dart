import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/parsers/comic_parser.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';

class ComicReaderScreen extends ConsumerStatefulWidget {
  const ComicReaderScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends ConsumerState<ComicReaderScreen> {
  ComicBookData? _data;
  Object? _error;
  late final PageController _pages;
  ReadingSessionTracker? _tracker;
  int _index = 0;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    final start = (widget.book.progress * 1000).round(); // encoded later
    _index = 0;
    _pages = PageController(initialPage: 0);
    _tracker = ref.read(sessionTrackerProvider);
    _tracker!.start(widget.book.id);
    _load();
    // silence unused
    assert(start >= 0);
  }

  Future<void> _load() async {
    try {
      final data = await ComicParser().parseFile(
        widget.book.filePath,
        fallbackTitle: widget.book.title,
      );
      if (!mounted) return;
      final initial =
          widget.book.lastLocation != null &&
              widget.book.lastLocation!.startsWith('page:')
          ? int.tryParse(widget.book.lastLocation!.substring(5)) ?? 0
          : (widget.book.progress * (data.pages.length - 1)).round();
      setState(() {
        _data = data;
        _index = initial.clamp(0, data.pages.length - 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pages.hasClients) _pages.jumpToPage(_index);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  double get _progress {
    final n = _data?.pages.length ?? 1;
    if (n <= 1) return 1;
    return (_index / (n - 1)).clamp(0.0, 1.0);
  }

  Future<void> _persist() async {
    await ref
        .read(bookRepositoryProvider)
        .updateProgress(widget.book.id, _progress, 'page:$_index');
    await ref.read(libraryProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _persist();
    _tracker?.stop();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              title: Text(
                _data?.title ?? widget.book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (_data != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${_index + 1}/${_data!.pages.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: _data == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await ref
                              .read(annotationRepositoryProvider)
                              .add(
                                Annotation(
                                  id: const Uuid().v4(),
                                  bookId: widget.book.id,
                                  type: AnnotationType.bookmark,
                                  createdAt: DateTime.now(),
                                  progress: _progress,
                                  location: 'page:$_index',
                                ),
                              );
                          ref.invalidate(allAnnotationsProvider);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Bookmark saved')),
                          );
                        },
                ),
              ],
            )
          : null,
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : _data == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: PageView.builder(
                controller: _pages,
                itemCount: _data!.pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _data!.pages[i];
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.memory(
                        page.bytes,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: _chromeVisible && _data != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white12,
                ),
              ),
            )
          : null,
    );
  }
}
