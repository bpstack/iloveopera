import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../providers/viewer_controller_provider.dart';
import '../providers/viewer_state_providers.dart';

/// Zoom controls driven by an explicit user factor relative to fit.
///
/// 100% == fit-to-page ([zoomFactorProvider] == 1.0). The displayed percentage
/// is the factor itself, NOT a ratio recomputed from pdfrx's absolute scale —
/// recomputing `calcMatrixForFit` every build made the label stick (fit and
/// current zoom shrank together). Driving the label from the factor keeps it
/// correct on the way down and stable across window resizes.
///
/// Note: the label reflects button-driven zoom. Pinch/trackpad gestures change
/// the actual scale without updating this factor (acceptable for desktop v1).
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  static const double _step = 1.25;
  static const double _minFactor = 0.25; // 25% of fit
  static const double _maxFactor = 8.0; // 800% of fit

  double? _fitScale(PdfViewerController controller, int page) {
    final m = controller.calcMatrixForFit(pageNumber: page < 1 ? 1 : page);
    return m?.getMaxScaleOnAxis();
  }

  Future<void> _setFactor(
    WidgetRef ref,
    PdfViewerController controller,
    int page,
    double rawFactor,
  ) async {
    final factor = rawFactor.clamp(_minFactor, _maxFactor);
    ref.read(zoomFactorProvider.notifier).set(factor);
    final fit = _fitScale(controller, page);
    if (fit == null || fit <= 0) return;
    await controller.setZoom(controller.centerPosition, fit * factor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(viewerControllerProvider);
    final factor = ref.watch(zoomFactorProvider);
    final page = ref.watch(currentPageProvider);
    final ready = controller != null && ref.watch(currentZoomProvider) > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir',
          icon: const Icon(Icons.zoom_out),
          onPressed: !ready
              ? null
              : () => _setFactor(ref, controller, page, factor / _step),
        ),
        SizedBox(
          width: 56,
          child: Text(
            ready ? '${(factor * 100).round()} %' : '—',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Aumentar',
          icon: const Icon(Icons.zoom_in),
          onPressed: !ready
              ? null
              : () => _setFactor(ref, controller, page, factor * _step),
        ),
        IconButton(
          tooltip: 'Ajustar a la página',
          icon: const Icon(Icons.fit_screen),
          onPressed: !ready
              ? null
              : () => _setFactor(ref, controller, page, 1.0),
        ),
      ],
    );
  }
}
