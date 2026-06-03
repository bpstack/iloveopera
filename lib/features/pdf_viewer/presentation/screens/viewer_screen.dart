import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../annotation/presentation/providers/annotation_providers.dart';
import '../../../annotation/presentation/widgets/font_picker.dart';
import '../../../annotation/presentation/widgets/tool_panel.dart';
import '../../domain/entities/pdf_failure.dart';
import '../providers/pdf_session_provider.dart';
import '../providers/viewer_state_providers.dart';
import '../widgets/page_navigation_bar.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/thumbnail_rail.dart';
import '../widgets/zoom_controls.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  bool _opening = false;

  Future<void> _openPdf() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final useCase = ref.read(openPdfFromPickerProvider);
      final result = await useCase();
      if (!mounted) return;
      result.when(
        success: (session) {
          // Reset annotation state for the new document.
          ref.read(annotationsProvider.notifier).clearAll();
          ref.read(selectedAnnotationProvider.notifier).clear();
          ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
          ref.read(pdfSessionProvider.notifier).set(session);
          ref.read(currentPageProvider.notifier).set(1);
          ref.read(currentZoomProvider.notifier).set(0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abierto: ${session.sourceName} (${session.pageCount} pág.)'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        failure: (error) {
          if (error is PdfCancelledByUser) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abrir PDF: $error')),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pdfSessionProvider);
    final hasDocument = session != null;
    final tool = ref.watch(annotationToolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(hasDocument ? session.sourceName : 'iloveopera'),
        actions: [
          if (hasDocument) ...[
            PageNavigationBar(totalPages: session.pageCount),
            const SizedBox(width: 8),
            ZoomControls(),
            const SizedBox(width: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _opening ? null : _openPdf,
              icon: _opening
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: const Text('Abrir PDF'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (hasDocument) const ThumbnailRail(),
          if (hasDocument) const ToolPanel(),
          if (hasDocument)
            _StyleBar(
              isTextTool: tool == AnnotationTool.addText,
              isRectTool: tool == AnnotationTool.addRect,
            ),
          if (hasDocument) const VerticalDivider(width: 1),
          Expanded(
            child: hasDocument
                ? const PdfViewerWidget()
                : _EmptyState(onOpen: _openPdf, busy: _opening),
          ),
        ],
      ),
    );
  }
}

class _StyleBar extends ConsumerWidget {
  const _StyleBar({required this.isTextTool, required this.isRectTool});

  final bool isTextTool;
  final bool isRectTool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isTextTool && !isRectTool) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isTextTool) ...const <Widget>[
            FontPicker(),
            SizedBox(width: 4),
            FontSizeField(),
            SizedBox(width: 8),
            Text('Color:'),
            SizedBox(width: 4),
            ColorSwatchButton(isText: true),
          ] else ...const <Widget>[
            Text('Color:'),
            SizedBox(width: 4),
            ColorSwatchButton(isText: false),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpen, required this.busy});

  final VoidCallback onOpen;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, size: 96, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Aquí irá el visor PDF',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Abre un PDF desde tu sistema de archivos para empezar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy ? null : onOpen,
            icon: const Icon(Icons.folder_open),
            label: const Text('Abrir PDF'),
          ),
        ],
      ),
    );
  }
}
