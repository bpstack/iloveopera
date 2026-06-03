import 'dart:math' show min, max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/annotation.dart';
import '../../domain/entities/page_rect.dart';
import '../../domain/entities/pdf_point.dart';
import '../painters/stroke_painter.dart';
import '../providers/annotation_providers.dart';

/// Per-page overlay widget. Returned by [PdfViewerParams.pageOverlaysBuilder]
/// for every visible page; renders all annotations of that page on top of
/// pdfrx's own rendering.
///
/// Text content is entered through a modal dialog (not inline) — editing inside
/// pdfrx's overlay fought pdfrx for keyboard focus, so a dialog (its own focus
/// scope) is reliable. Coordinates are always in PDF points (R5); a single
/// scale factor maps points to overlay pixels.
class AnnotationLayer extends ConsumerStatefulWidget {
  const AnnotationLayer({super.key, required this.page});
  final PdfPage page;

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  PdfPage get page => widget.page;

  // Active resize state — updated on every pointer move, committed on pan end.
  String? _resizingId;
  double _resizeDx = 0;
  double _resizeDy = 0;

  void _onResizeUpdate(String id, double dx, double dy) {
    setState(() {
      _resizingId = id;
      _resizeDx += dx;
      _resizeDy += dy;
    });
  }

  void _onResizeEnd(String id, double scale) {
    final a = ref.read(annotationsProvider).where((a) => a.id == id).firstOrNull;
    if (a != null) {
      final r = a.rect;
      // Text: only width matters (height stays 0 = auto).
      // Rect/highlight: both width and height.
      final baseW = r.width > 0 ? r.width : 120.0;
      final baseH = r.height > 0 ? r.height : 40.0;
      final newW = (baseW + _resizeDx / scale).clamp(20.0, double.infinity);
      final newH = a is TextAnnotation
          ? 0.0
          : (baseH + _resizeDy / scale).clamp(10.0, double.infinity);
      ref.read(annotationsProvider.notifier).moveLocal(
            id, r.copyWith(width: newW, height: newH));
    }
    setState(() { _resizingId = null; _resizeDx = 0; _resizeDy = 0; });
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(annotationToolProvider);
    final annotations = ref.watch(annotationsForPageProvider(page.pageNumber));
    final selectedId = ref.watch(selectedAnnotationProvider);
    final pageWidth = page.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale =
            constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth / pageWidth;

        final cursor = switch (tool) {
          AnnotationTool.addText => SystemMouseCursors.text,
          AnnotationTool.addStroke => SystemMouseCursors.precise,
          AnnotationTool.addRect ||
          AnnotationTool.addHighlight =>
            SystemMouseCursors.cell,
          _ => MouseCursor.defer,
        };

        return MouseRegion(
          cursor: cursor,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Tap capture layer for point-placement tools.
              if (tool == AnnotationTool.addText ||
                  tool == AnnotationTool.addRect ||
                  tool == AnnotationTool.addHighlight)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _onBackgroundTap(context, details.localPosition, scale),
                    child: const SizedBox.expand(),
                  ),
                ),

              // Existing annotations + resize handles (separate Positioned so
              // they never compete with the move GestureDetector).
              for (final a in annotations) ...[
                _buildPositioned(a, scale, selectedId),
                if (a.id == selectedId &&
                    tool == AnnotationTool.select &&
                    a is! StrokeAnnotation)
                  _buildResizeHandle(a, scale),
              ],

              // Live stroke drawing layer
              if (tool == AnnotationTool.addStroke)
                Positioned.fill(
                  child: _StrokeDrawingLayer(page: page, scale: scale),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Resize handle as a standalone [Positioned] in the outer Stack.
  /// Keeping it outside [_AnnotationWidget] means it never competes with
  /// the move [GestureDetector] in the gesture arena.
  Widget _buildResizeHandle(Annotation a, double scale) {
    final isResizing = _resizingId == a.id;

    // Compute effective width/height in PDF points for handle placement.
    final double effW;
    final double effH;
    if (a is TextAnnotation) {
      // For auto-size text (width==0) use 120 pt as the base.
      final baseW = a.rect.width > 0 ? a.rect.width : 120.0;
      effW = (baseW + (isResizing ? _resizeDx / scale : 0)).clamp(20.0, double.infinity);
      effH = a.rect.height > 0
          ? (a.rect.height + (isResizing ? _resizeDy / scale : 0)).clamp(10.0, double.infinity)
          : 20.0; // approximate for auto-height text
    } else {
      effW = (a.rect.width + (isResizing ? _resizeDx / scale : 0)).clamp(10.0, double.infinity);
      effH = (a.rect.height + (isResizing ? _resizeDy / scale : 0)).clamp(10.0, double.infinity);
    }

    // Place the 14×14 handle centred on the bottom-right corner.
    final left = (a.rect.x * scale + effW * scale - 7).clamp(0.0, double.infinity);
    final top  = (a.rect.y * scale + effH * scale - 7).clamp(0.0, double.infinity);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _onResizeUpdate(a.id, d.delta.dx, d.delta.dy),
        onPanEnd: (_) => _onResizeEnd(a.id, scale),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.indigoAccent,
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  /// Builds a [Positioned] for [a], expanding its dimensions live during resize.
  Widget _buildPositioned(Annotation a, double scale, String? selectedId) {
    final isResizing = _resizingId == a.id;

    double? displayW;
    double? displayH;

    if (a is TextAnnotation) {
      // width: null (auto) until the user resizes. During resize use 120 pt base.
      final baseW = a.rect.width > 0 ? a.rect.width : (isResizing ? 120.0 : null);
      displayW = baseW != null
          ? (baseW + (isResizing ? _resizeDx / scale : 0)).clamp(20.0, double.infinity)
          : null;
      displayH = null; // always auto-height for text
    } else {
      displayW = (a.rect.width + (isResizing ? _resizeDx / scale : 0))
          .clamp(10.0, double.infinity);
      displayH = (a.rect.height + (isResizing ? _resizeDy / scale : 0))
          .clamp(10.0, double.infinity);
    }

    return Positioned(
      left: a.rect.x * scale,
      top: a.rect.y * scale,
      width: displayW != null ? displayW * scale : null,
      height: displayH != null ? displayH * scale : null,
      child: _AnnotationWidget(
        key: ValueKey(a.id),
        annotation: a,
        scale: scale,
        isSelected: a.id == selectedId,
        autoSizeText: a is TextAnnotation && displayW == null,
        onResizeUpdate: _onResizeUpdate,
        onResizeEnd: _onResizeEnd,
      ),
    );
  }

  Future<void> _onBackgroundTap(
    BuildContext context,
    Offset localPosition,
    double scale,
  ) async {
    final tool = ref.read(annotationToolProvider);
    if (tool == AnnotationTool.select) {
      ref.read(selectedAnnotationProvider.notifier).clear();
      return;
    }

    final double xPoints = localPosition.dx / scale;
    final double yPoints = localPosition.dy / scale;
    const double defaultRectW = 150;
    const double defaultRectH = 40;
    final double clampedX = xPoints.clamp(0, page.width.toDouble());
    final double clampedY = yPoints.clamp(0, page.height.toDouble());
    final double clampedRectX = xPoints.clamp(0, page.width - defaultRectW);
    final double clampedRectY = yPoints.clamp(0, page.height - defaultRectH);
    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';

    if (tool == AnnotationTool.addText) {
      final text = await showAnnotationTextDialog(context, initialText: '');
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      if (text == null || text.trim().isEmpty) return;
      final style = ref.read(textStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.text(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedX, y: clampedY, width: 0, height: 0),
            text: text.trim(),
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            colorArgb: style.colorArgb,
          ));
      ref.read(selectedAnnotationProvider.notifier).set(id);
    } else if (tool == AnnotationTool.addRect) {
      final style = ref.read(rectStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.rect(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedRectX, y: clampedRectY, width: defaultRectW, height: defaultRectH),
            colorArgb: style.colorArgb,
            opacity: style.opacity,
          ));
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      ref.read(selectedAnnotationProvider.notifier).set(id);
    } else if (tool == AnnotationTool.addHighlight) {
      final style = ref.read(highlightStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.highlight(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedRectX, y: clampedRectY, width: defaultRectW, height: defaultRectH),
            colorArgb: style.colorArgb,
            opacity: style.opacity,
          ));
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      ref.read(selectedAnnotationProvider.notifier).set(id);
    }
  }
}

/// Modal dialog to enter/edit annotation text. Returns the text, or `null` if
/// cancelled. Lives outside pdfrx's focus scope, so typing (incl. Space) works.
Future<String?> showAnnotationTextDialog(
  BuildContext context, {
  required String initialText,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _TextInputDialog(initialText: initialText),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({required this.initialText});
  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Texto'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(hintText: 'Escribe el texto'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live stroke drawing
// ---------------------------------------------------------------------------

/// Captures pan gestures and draws the stroke in progress using [InProgressStrokePainter].
/// On pan end, converts screen points to PDF points and commits a [StrokeAnnotation].
/// Stays in [AnnotationTool.addStroke] mode after each stroke so multiple
/// strokes can be drawn without re-selecting the tool.
class _StrokeDrawingLayer extends ConsumerStatefulWidget {
  const _StrokeDrawingLayer({required this.page, required this.scale});

  final PdfPage page;
  final double scale;

  @override
  ConsumerState<_StrokeDrawingLayer> createState() => _StrokeDrawingLayerState();
}

class _StrokeDrawingLayerState extends ConsumerState<_StrokeDrawingLayer> {
  final List<Offset> _screenPoints = [];

  @override
  Widget build(BuildContext context) {
    final strokeStyle = ref.watch(strokeStyleProvider);
    final strokeWidthPx = strokeStyle.strokeWidth * widget.scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => setState(() {
        _screenPoints
          ..clear()
          ..add(d.localPosition);
      }),
      onPanUpdate: (d) => setState(() => _screenPoints.add(d.localPosition)),
      onPanEnd: (_) => _commitStroke(),
      child: CustomPaint(
        painter: InProgressStrokePainter(
          points: List<Offset>.from(_screenPoints),
          colorArgb: strokeStyle.colorArgb,
          strokeWidthPx: strokeWidthPx,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  void _commitStroke() {
    if (_screenPoints.length < 2) {
      setState(() => _screenPoints.clear());
      return;
    }

    final scale = widget.scale;
    final page = widget.page;

    // Convert screen pixels → PDF points (page-absolute)
    final pdfPoints = _screenPoints
        .map((p) => PagePoint(x: p.dx / scale, y: p.dy / scale))
        .toList(growable: false);

    // Bounding box with a small padding equal to half stroke width
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final p in pdfPoints) {
      minX = min(minX, p.x);
      minY = min(minY, p.y);
      maxX = max(maxX, p.x);
      maxY = max(maxY, p.y);
    }

    final strokeStyle = ref.read(strokeStyleProvider);
    final pad = strokeStyle.strokeWidth / 2;
    final boxX = (minX - pad).clamp(0.0, page.width);
    final boxY = (minY - pad).clamp(0.0, page.height);
    final boxW = ((maxX - minX + pad * 2)).clamp(1.0, page.width - boxX);
    final boxH = ((maxY - minY + pad * 2)).clamp(1.0, page.height - boxY);

    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';
    ref.read(annotationsProvider.notifier).addLocal(Annotation.stroke(
          id: id,
          pageNumber: page.pageNumber,
          points: pdfPoints,
          rect: PageRect(x: boxX, y: boxY, width: boxW, height: boxH),
          colorArgb: strokeStyle.colorArgb,
          strokeWidth: strokeStyle.strokeWidth,
        ));

    setState(() => _screenPoints.clear());
  }
}

// ---------------------------------------------------------------------------
// Per-annotation widget
// ---------------------------------------------------------------------------

/// A single annotation, positioned and interactive.
///
/// Dragging uses LOCAL state (a temporary screen-space offset) committed to the
/// store only on pan end — avoids rebuilding the whole overlay per pointer move.
class _AnnotationWidget extends ConsumerStatefulWidget {
  const _AnnotationWidget({
    super.key,
    required this.annotation,
    required this.scale,
    required this.isSelected,
    required this.autoSizeText,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  final Annotation annotation;
  final double scale;
  final bool isSelected;
  /// True when this TextAnnotation has no explicit width and should auto-size.
  final bool autoSizeText;
  // Kept in signature for potential future use; currently handled in parent.
  final void Function(String id, double dx, double dy) onResizeUpdate;
  final void Function(String id, double scale) onResizeEnd;

  @override
  ConsumerState<_AnnotationWidget> createState() => _AnnotationWidgetState();
}

class _AnnotationWidgetState extends ConsumerState<_AnnotationWidget> {
  Offset _drag = Offset.zero;

  Future<void> _editText() async {
    final a = widget.annotation;
    if (a is! TextAnnotation) return;
    final text = await showAnnotationTextDialog(context, initialText: a.text);
    if (text == null) return;
    if (text.trim().isEmpty) {
      ref.read(annotationsProvider.notifier).removeLocal(a.id);
    } else {
      ref.read(annotationsProvider.notifier).updateLocal(a.copyWith(text: text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(annotationToolProvider);
    final a = widget.annotation;
    final scale = widget.scale;
    final canDrag = tool == AnnotationTool.select;

    final Widget visual = switch (a) {
      TextAnnotation(:final fontFamily, :final fontSize, :final colorArgb, :final text) =>
        _TextAnnotationVisual(
          text: text,
          fontFamily: fontFamily,
          fontSize: fontSize * scale,
          colorArgb: colorArgb,
          isSelected: widget.isSelected,
          autoSize: widget.autoSizeText,
        ),
      RectAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: widget.isSelected,
        ),
      StrokeAnnotation(:final points, :final colorArgb, :final strokeWidth, :final rect) =>
        CustomPaint(
          painter: StrokePainter(
            points: points,
            offsetX: rect.x,
            offsetY: rect.y,
            scale: scale,
            colorArgb: colorArgb,
            strokeWidth: strokeWidth,
          ),
          child: widget.isSelected
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.indigoAccent, width: 1.5),
                  ),
                )
              : const SizedBox.expand(),
        ),
      HighlightAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: widget.isSelected,
        ),
    };

    return Transform.translate(
      offset: _drag,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(selectedAnnotationProvider.notifier).set(a.id),
        onDoubleTap: a is TextAnnotation ? _editText : null,
        onPanStart: canDrag
            ? (_) => ref.read(selectedAnnotationProvider.notifier).set(a.id)
            : null,
        onPanUpdate: canDrag ? (d) => setState(() => _drag += d.delta) : null,
        onPanEnd: canDrag
            ? (_) {
                final r = a.rect;
                ref.read(annotationsProvider.notifier).moveLocal(
                      a.id,
                      r.copyWith(
                        x: r.x + _drag.dx / scale,
                        y: r.y + _drag.dy / scale,
                      ),
                    );
                setState(() => _drag = Offset.zero);
              }
            : null,
        child: visual,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visual widgets
// ---------------------------------------------------------------------------

class _TextAnnotationVisual extends StatelessWidget {
  const _TextAnnotationVisual({
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.colorArgb,
    required this.isSelected,
    required this.autoSize,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorArgb;
  final bool isSelected;
  /// When true the widget shrink-wraps to fit the text (no explicit parent width).
  /// When false the parent Positioned constrains the width and text wraps within it.
  final bool autoSize;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: Color(colorArgb),
          height: 1.2,
        ),
      ),
    );
    if (autoSize) {
      return IntrinsicWidth(child: IntrinsicHeight(child: inner));
    }
    return inner;
  }
}

class _RectAnnotationVisual extends StatelessWidget {
  const _RectAnnotationVisual({
    required this.colorArgb,
    required this.opacity,
    required this.isSelected,
  });

  final int colorArgb;
  final double opacity;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(colorArgb).withValues(alpha: opacity),
        border: isSelected
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
    );
  }
}
