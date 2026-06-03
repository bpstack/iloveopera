import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../annotation/presentation/providers/annotation_providers.dart';
import '../../../annotation/presentation/widgets/font_picker.dart';
import '../../../annotation/presentation/widgets/tool_panel.dart';
import '../../../export/presentation/providers/export_providers.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../../../project/presentation/screens/projects_screen.dart';
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

  Future<void> _saveProject() async {
    try {
      final project =
          await ref.read(projectsProvider.notifier).saveCurrentSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proyecto guardado: ${project.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _openProjectsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProjectsScreen()),
    );
  }

  Future<void> _exportPdf() async {
    await ref.read(exportProvider.notifier).exportPdf();
    if (!mounted) return;
    ref.read(exportProvider).when(
      data: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF exportado correctamente.'),
          duration: Duration(seconds: 3),
        ),
      ),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      ),
      loading: () {},
    );
  }

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
    final exportState = ref.watch(exportProvider);
    final isExporting = exportState.isLoading;

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
          if (hasDocument) ...[
            IconButton(
              tooltip: 'Proyectos guardados',
              icon: const Icon(Icons.folder_special_outlined),
              onPressed: _openProjectsScreen,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onTertiaryContainer,
                ),
                onPressed: _saveProject,
                icon: const Icon(Icons.save_outlined),
                label: Text(session.projectId != null
                    ? 'Actualizar proyecto'
                    : 'Guardar proyecto'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                onPressed: isExporting ? null : _exportPdf,
                icon: isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text('Exportar PDF'),
              ),
            ),
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
