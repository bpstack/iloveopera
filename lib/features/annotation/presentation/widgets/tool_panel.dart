import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/annotation_providers.dart';

/// Left-hand vertical palette: tool selector + delete selected.
class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final selectedId = ref.watch(selectedAnnotationProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget btn(IconData icon, String label, AnnotationTool t) {
      final active = tool == t;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: IconButton(
          tooltip: label,
          isSelected: active,
          icon: Icon(icon),
          onPressed: () => ref.read(annotationToolProvider.notifier).set(t),
        ),
      );
    }

    return Container(
      width: 56,
      color: scheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          btn(Icons.pan_tool_alt, 'Seleccionar (mover/borrar)', AnnotationTool.select),
          btn(Icons.title, 'Añadir texto', AnnotationTool.addText),
          btn(Icons.crop_square, 'Añadir rect (tipp-ex)', AnnotationTool.addRect),
          const Divider(height: 12),
          IconButton(
            tooltip: 'Eliminar selección',
            icon: const Icon(Icons.delete_outline),
            onPressed: selectedId == null
                ? null
                : () => ref.read(annotationsProvider.notifier).removeLocal(selectedId),
          ),
        ],
      ),
    );
  }
}
