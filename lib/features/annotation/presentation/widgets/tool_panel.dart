import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/annotation_providers.dart';

/// Vertical icon toolbar (left side). Groups: navigation, annotation tools,
/// history, actions. (ROADMAP Fase 6 toolbar spec.)
class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final selectedId = ref.watch(selectedAnnotationProvider);
    final undoRedo = ref.watch(undoRedoProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget btn(
      IconData icon,
      String tooltip,
      AnnotationTool t, {
      Color? activeColor,
    }) {
      final active = tool == t;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Tooltip(
          message: tooltip,
          preferBelow: false,
          child: IconButton(
            icon: Icon(icon, size: 22),
            isSelected: active,
            selectedIcon: Icon(icon, size: 22, color: activeColor ?? scheme.primary),
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            onPressed: () =>
                ref.read(annotationToolProvider.notifier).set(t),
          ),
        ),
      );
    }

    Widget iconAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Tooltip(
          message: tooltip,
          preferBelow: false,
          child: IconButton(
            icon: Icon(icon, size: 22),
            onPressed: onPressed,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget divider() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(
            height: 1,
            indent: 10,
            endIndent: 10,
            color: scheme.outlineVariant,
          ),
        );

    return Container(
      width: 48,
      color: scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // Navigation / selection
          btn(Icons.pan_tool_alt_outlined, 'Seleccionar · mover', AnnotationTool.select),

          divider(),

          // Annotation tools
          btn(Icons.title, 'Añadir texto', AnnotationTool.addText),
          btn(Icons.rectangle_outlined, 'Añadir rect (tipp-ex)', AnnotationTool.addRect),
          btn(Icons.brush_outlined, 'Dibujar a mano alzada', AnnotationTool.addStroke),
          btn(Icons.highlight, 'Resaltar zona', AnnotationTool.addHighlight),

          divider(),

          // History
          iconAction(
            icon: Icons.undo,
            tooltip: 'Deshacer  Ctrl+Z',
            onPressed: undoRedo.canUndo
                ? () => ref.read(annotationsProvider.notifier).undoAnnotations()
                : null,
          ),
          iconAction(
            icon: Icons.redo,
            tooltip: 'Rehacer  Ctrl+Y',
            onPressed: undoRedo.canRedo
                ? () => ref.read(annotationsProvider.notifier).redoAnnotations()
                : null,
          ),

          divider(),

          // Actions
          iconAction(
            icon: Icons.delete_outline,
            tooltip: 'Eliminar selección',
            onPressed: selectedId == null
                ? null
                : () =>
                    ref.read(annotationsProvider.notifier).removeLocal(selectedId),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
