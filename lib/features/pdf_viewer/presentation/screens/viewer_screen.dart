import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          const VerticalDivider(width: 1),
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
