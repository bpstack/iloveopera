import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Zoom in / out / reset buttons that operate on the active
/// [PdfViewerController] exposed by [viewerControllerProvider].
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(currentZoomProvider);
    final controller = ref.watch(viewerControllerProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir',
          icon: const Icon(Icons.zoom_out),
          onPressed: controller == null ? null : () => controller.zoomDown(),
        ),
        SizedBox(
          width: 56,
          child: Text(
            zoom <= 0 ? '—' : '${(zoom * 100).round()} %',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.zoom_in),
          onPressed: controller == null ? null : () => controller.zoomUp(),
        ),
        IconButton(
          tooltip: 'Ajustar al ancho',
          icon: const Icon(Icons.fit_screen),
          onPressed: controller == null
              ? null
              : () async {
                  final m = controller.calcMatrixForFit(pageNumber: 1);
                  if (m != null) {
                    await controller.goTo(m);
                  }
                },
        ),
      ],
    );
  }
}
