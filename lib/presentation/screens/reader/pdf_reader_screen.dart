import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/annotation.dart';
import '../../../domain/models/book.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../providers/providers.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final _controller = PdfViewerController();
  ReadingSessionTracker? _tracker;
  double _progress = 0;
  int _pageCount = 0;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _progress = widget.book.progress;
    _tracker = ref.read(sessionTrackerProvider);
    _tracker!.start(widget.book.id);
  }

  Future<void> _persist() async {
    await ref.read(bookRepositoryProvider).updateProgress(
          widget.book.id,
          _progress,
          _controller.isReady
              ? 'page:${_controller.pageNumber}'
              : null,
        );
    await ref.read(libraryProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _persist();
    _tracker?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    return Scaffold(
      appBar: _chromeVisible
          ? AppBar(
              title: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: strings.addBookmark,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: () async {
                    await ref.read(annotationRepositoryProvider).add(
                          Annotation(
                            id: const Uuid().v4(),
                            bookId: widget.book.id,
                            type: AnnotationType.bookmark,
                            createdAt: DateTime.now(),
                            location: _controller.isReady
                                ? 'page:${_controller.pageNumber}'
                                : null,
                            progress: _progress,
                          ),
                        );
                    ref.invalidate(allAnnotationsProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.addBookmark)),
                    );
                  },
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _chromeVisible = !_chromeVisible),
        child: PdfViewer.file(
          widget.book.filePath,
          controller: _controller,
          params: PdfViewerParams(
            onPageChanged: (page) {
              if (page == null) return;
              if (_pageCount > 0) {
                setState(() => _progress = page / _pageCount);
              }
            },
            onViewerReady: (doc, controller) {
              _pageCount = doc.pages.length;
              if (_progress > 0 && _pageCount > 0) {
                final page = (_progress * _pageCount).round().clamp(1, _pageCount);
                controller.goToPage(pageNumber: page);
              }
              setState(() {});
            },
          ),
        ),
      ),
      bottomNavigationBar: _chromeVisible
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: _progress.clamp(0, 1)),
                    const SizedBox(height: 4),
                    Text(
                      _controller.isReady && _pageCount > 0
                          ? '${_controller.pageNumber} / $_pageCount'
                          : '${(_progress * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
