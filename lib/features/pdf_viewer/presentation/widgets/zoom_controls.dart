import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Zoom controls driven by pdfrx's REAL absolute scale.
///
/// Both the displayed percentage and the +/- targets are derived from
/// `controller.currentZoom` (the actual on-screen scale), so the number can
/// never desync from the image. 100% == actual size (1:1). The "fit" button
/// snaps to fit-to-page.
///
/// Earlier attempts derived the % from a fit baseline (`calcMatrixForFit`),
/// but that scale is not stable, so the label drifted from reality. Reading the
/// live scale fixes that.
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  static const double _step = 1.25;
  static const double _minZoom = 0.1; // 10%
  static const double _maxZoom = 10.0; // 1000%

  Future<void> _zoomTo(PdfViewerController controller, double target) async {
    final clamped = target.clamp(_minZoom, _maxZoom);
    // Instant (no animation): rapid clicks must not queue 200ms tweens.
    await controller.setZoom(
      controller.centerPosition,
      clamped,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(viewerControllerProvider);
    final zoom = ref.watch(currentZoomProvider); // live absolute scale
    final page = ref.watch(currentPageProvider);
    final ready = controller != null && zoom > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir',
          icon: const Icon(Icons.zoom_out),
          onPressed: !ready
              ? null
              : () => _zoomTo(controller, controller.currentZoom / _step),
        ),
        SizedBox(
          width: 56,
          child: Text(
            ready ? '${(zoom * 100).round()} %' : '—',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.zoom_in),
          onPressed: !ready
              ? null
              : () => _zoomTo(controller, controller.currentZoom * _step),
        ),
        IconButton(
          tooltip: 'Ajustar a la página',
          icon: const Icon(Icons.fit_screen),
          onPressed: !ready
              ? null
              : () => controller.goTo(
                  controller.calcMatrixForFit(pageNumber: page < 1 ? 1 : page),
                  duration: Duration.zero,
                ),
        ),
      ],
    );
  }
}
