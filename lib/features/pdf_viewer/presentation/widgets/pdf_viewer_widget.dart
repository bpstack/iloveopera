import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../annotation/presentation/providers/annotation_providers.dart';
import '../../../annotation/presentation/widgets/annotation_layer.dart';
import '../../data/datasources/pdfrx_data_source.dart';
import '../providers/pdf_session_provider.dart';
import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Wraps pdfrx's [PdfViewer] with Riverpod integration.
///
/// The widget owns the [PdfViewerController], publishes it via
/// [viewerControllerProvider] for sibling widgets (zoom controls, page
/// navigation, thumbnail rail), and mirrors the controller's current page
/// and zoom into [currentPageProvider] / [currentZoomProvider].
class PdfViewerWidget extends ConsumerStatefulWidget {
  const PdfViewerWidget({super.key});

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  late final PdfViewerController _controller;
  VoidCallback? _removeListener;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _controller.addListener(_onControllerChanged);
    _removeListener = () => _controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(viewerControllerProvider.notifier).set(_controller);
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final page = _controller.pageNumber;
    if (page != null && page > 0) {
      ref.read(currentPageProvider.notifier).set(page);
    }
    final zoom = _controller.currentZoom;
    if (zoom > 0) {
      ref.read(currentZoomProvider.notifier).set(zoom);
    }
  }

  @override
  void dispose() {
    _removeListener?.call();
    if (ref.read(viewerControllerProvider) == _controller) {
      ref.read(viewerControllerProvider.notifier).set(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PdfrxDataSource dataSource = ref.watch(pdfrxDataSourceProvider);
    final PdfDocument? document = dataSource.document;
    if (document == null) {
      // Guard: ViewerScreen should not mount us without a document, but if
      // it does, render a placeholder rather than crash.
      return const SizedBox.shrink();
    }
    // The session may have been closed by the user; check via provider too.
    final hasSession = ref.watch(pdfSessionProvider) != null;
    if (!hasSession) return const SizedBox.shrink();

    // In "select" mode the user drags annotations, so the viewer's own pan
    // gesture is disabled to avoid fighting the drag (scroll wheel/scrollbar
    // still work). In add modes panning stays on.
    final tool = ref.watch(annotationToolProvider);
    final panEnabled = tool != AnnotationTool.select;

    // While editing a text annotation, disable pdfrx's keyboard navigation so
    // Space/arrows go to the TextField instead of scrolling the page.
    final isEditingText = ref.watch(editingAnnotationProvider) != null;

    return PdfViewer(
      PdfDocumentRefDirect(document),
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor: Colors.transparent,
        panEnabled: panEnabled,
        enableKeyboardNavigation: !isEditingText,
        pageDropShadow: const BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          spreadRadius: 1,
          offset: Offset(1, 2),
        ),
        // Annotations are painted in page coordinates by pdfrx (R5):
        // the builder is called for each visible page with the page's
        // bounding rect on screen, and our AnnotationLayer handles the
        // points-to-pixels mapping via a single scale factor.
        pageOverlaysBuilder: (context, pageRect, page) => <Widget>[
          Positioned.fromRect(
            rect: pageRect,
            child: AnnotationLayer(page: page),
          ),
        ],
      ),
    );
  }
}
