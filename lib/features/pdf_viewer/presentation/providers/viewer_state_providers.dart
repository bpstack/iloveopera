import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1-based current page number. `0` when no document is open.
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int pageNumber) => state = pageNumber;
}

final currentPageProvider =
    NotifierProvider<CurrentPageNotifier, int>(CurrentPageNotifier.new);

/// Current zoom ratio. `1.0` means fit-to-view. `0` when no document is open.
class CurrentZoomNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void set(double zoom) => state = zoom;
}

final currentZoomProvider =
    NotifierProvider<CurrentZoomNotifier, double>(CurrentZoomNotifier.new);

/// User-controlled zoom factor relative to fit. `1.0` == fit-to-page.
///
/// This is the source of truth for the displayed zoom percentage. It is driven
/// by the +/-/fit buttons (not derived from pdfrx's absolute scale), so the
/// label never gets stuck and stays stable across window resizes.
class ZoomFactorNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void set(double factor) => state = factor;
  void reset() => state = 1.0;
}

final zoomFactorProvider =
    NotifierProvider<ZoomFactorNotifier, double>(ZoomFactorNotifier.new);
