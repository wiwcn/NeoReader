import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/reading_theme.dart';
import '../../../data/services/reading_session_tracker.dart';
import '../../../domain/models/annotation.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/book.dart';
import '../../providers/providers.dart';

enum _PdfFitMode { fitWidth, fitPage }

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
  int _currentPage = 1;
  bool _chromeVisible = true;
  _PdfFitMode _fitMode = _PdfFitMode.fitWidth;
  bool? _nightInvertOverride;

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
          _controller.isReady ? 'page:${_controller.pageNumber}' : null,
        );
    await ref.read(libraryProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _persist();
    _tracker?.stop();
    super.dispose();
  }

  void _goRelative(int delta) {
    if (!_controller.isReady || _pageCount <= 0) return;
    final next = (_currentPage + delta).clamp(1, _pageCount);
    _controller.goToPage(pageNumber: next);
  }

  Future<void> _applyFit() async {
    if (!_controller.isReady) return;
    try {
      final view = _controller.viewSize;
      final layout = _controller.layout;
      if (view.width <= 0 || layout.pageLayouts.isEmpty) return;
      final pageRect = layout.pageLayouts[
          (_currentPage - 1).clamp(0, layout.pageLayouts.length - 1)];
      const margin = 8.0;
      late final double targetZoom;
      if (_fitMode == _PdfFitMode.fitWidth) {
        targetZoom = _controller.alternativeFitScale ??
            ((view.width - margin * 2) / pageRect.width);
      } else {
        final zx = (view.width - margin * 2) / pageRect.width;
        final zy = (view.height - margin * 2) / pageRect.height;
        targetZoom = math.min(zx, zy);
      }
      await _controller.goToPage(pageNumber: _currentPage);
      await _controller.setZoom(
        _controller.centerPosition,
        targetZoom.clamp(0.3, 8.0),
      );
    } catch (_) {
      // Best-effort across pdfrx versions.
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final readingNight = settings.readingTheme == ReadingThemeMode.night;
    final useInvert = _nightInvertOverride ?? readingNight;
    final bg = useInvert
        ? const Color(0xFF1A1B1E)
        : Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: bg.withValues(alpha: 0.92),
              title: Text(widget.book.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: strings.pdfFitWidth,
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: _fitMode == _PdfFitMode.fitWidth
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () {
                    setState(() => _fitMode = _PdfFitMode.fitWidth);
                    _applyFit();
                  },
                ),
                IconButton(
                  tooltip: strings.pdfFitPage,
                  icon: Icon(
                    Icons.fit_screen_rounded,
                    color: _fitMode == _PdfFitMode.fitPage
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () {
                    setState(() => _fitMode = _PdfFitMode.fitPage);
                    _applyFit();
                  },
                ),
                IconButton(
                  tooltip: strings.pdfNightInvert,
                  icon: Icon(
                    useInvert
                        ? Icons.dark_mode_rounded
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _nightInvertOverride = !useInvert;
                    });
                  },
                ),
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
        onDoubleTap: () async {
          if (!_controller.isReady) return;
          try {
            final z = _controller.currentZoom;
            final next = z < 1.5 ? z * 1.8 : z / 1.8;
            await _controller.setZoom(_controller.centerPosition, next);
          } catch (_) {}
        },
        child: PdfViewer.file(
          widget.book.filePath,
          controller: _controller,
          params: PdfViewerParams(
            backgroundColor: bg,
            pageImageColorFilter: useInvert
                ? const ColorFilter.matrix(<double>[
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ])
                : null,
            pageAnchor: PdfPageAnchor.top,
            onPageChanged: (page) {
              if (page == null) return;
              _currentPage = page;
              if (_pageCount > 0) {
                setState(() => _progress = page / _pageCount);
              }
            },
            onViewerReady: (doc, controller) async {
              _pageCount = doc.pages.length;
              if (_progress > 0 && _pageCount > 0) {
                final page =
                    (_progress * _pageCount).round().clamp(1, _pageCount);
                await controller.goToPage(pageNumber: page);
                _currentPage = page;
              }
              setState(() {});
              await Future<void>.delayed(const Duration(milliseconds: 50));
              await _applyFit();
            },
            viewerOverlayBuilder: (context, size, handleLinkTap) {
              if (!_chromeVisible) return const <Widget>[];
              return [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavChip(
                          icon: Icons.chevron_left_rounded,
                          label: strings.pdfPrevPage,
                          onTap: () => _goRelative(-1),
                        ),
                        _NavChip(
                          icon: Icons.chevron_right_rounded,
                          label: strings.pdfNextPage,
                          onTap: () => _goRelative(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
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
                          ? '$_currentPage / $_pageCount'
                          : '${(_progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.85,
          ),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
