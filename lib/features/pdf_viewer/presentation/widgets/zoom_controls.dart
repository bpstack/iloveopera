import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Zoom controls that operate RELATIVE TO FIT instead of pdfrx's absolute
/// scale or its predefined zoom steps.
///
/// Why: pdfrx's `currentZoom` is an absolute scale factor and `zoomUp/zoomDown`
/// cycle through predefined levels. When the window is resized the viewer
/// re-fits, the absolute scale changes (the displayed % drifted) and the
/// predefined minimum could be reached, leaving the "-" button stuck.
///
/// Here, 100% == fit-to-page. The displayed percentage is `currentZoom /
/// fitScale`, which stays stable across window resizes (both terms scale
/// together). Zoom in/out multiply/divide the current factor and apply an
/// absolute target via `setZoom`, clamped to [25%, 800%] of fit — so zoom-out
/// always has room.
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  static const double _step = 1.25;
  static const double _minFactor = 0.25; // 25% of fit
  static const double _maxFactor = 8.0; // 800% of fit

  /// Scale that fits the given page into the viewport, or null if the
  /// controller is not ready yet.
  double? _fitScale(PdfViewerController controller, int page) {
    final m = controller.calcMatrixForFit(pageNumber: page < 1 ? 1 : page);
    return m?.getMaxScaleOnAxis();
  }

  /// Current zoom expressed as a multiple of fit (1.0 == fit).
  double _currentFactor(PdfViewerController controller, int page) {
    final fit = _fitScale(controller, page);
    if (fit == null || fit <= 0) return 1;
    return controller.currentZoom / fit;
  }

  Future<void> _applyFactor(
    PdfViewerController controller,
    int page,
    double factor,
  ) async {
    final fit = _fitScale(controller, page);
    if (fit == null || fit <= 0) return;
    final clamped = factor.clamp(_minFactor, _maxFactor);
    await controller.setZoom(controller.centerPosition, fit * clamped);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(viewerControllerProvider);
    final zoom = ref.watch(currentZoomProvider);
    final page = ref.watch(currentPageProvider);

    int? percent;
    if (controller != null && zoom > 0) {
      final fit = _fitScale(controller, page);
      if (fit != null && fit > 0) percent = (zoom / fit * 100).round();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir',
          icon: const Icon(Icons.zoom_out),
          onPressed: controller == null
              ? null
              : () => _applyFactor(
                  controller,
                  page,
                  _currentFactor(controller, page) / _step,
                ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            percent == null ? '—' : '$percent %',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.zoom_in),
          onPressed: controller == null
              ? null
              : () => _applyFactor(
                  controller,
                  page,
                  _currentFactor(controller, page) * _step,
                ),
        ),
        IconButton(
          tooltip: 'Ajustar a la página',
          icon: const Icon(Icons.fit_screen),
          onPressed: controller == null
              ? null
              : () => _applyFactor(controller, page, 1.0), // 100% = fit
        ),
      ],
    );
  }
}
