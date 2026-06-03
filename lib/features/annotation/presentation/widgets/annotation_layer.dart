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
class AnnotationLayer extends ConsumerWidget {
  const AnnotationLayer({super.key, required this.page});

  final PdfPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final annotations = ref.watch(annotationsForPageProvider(page.pageNumber));
    final selectedId = ref.watch(selectedAnnotationProvider);
    final pageWidth = page.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale =
            constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth / pageWidth;

        final isAddMode = tool == AnnotationTool.addText ||
            tool == AnnotationTool.addRect ||
            tool == AnnotationTool.addHighlight ||
            tool == AnnotationTool.addStroke;

        // Cursor hint (desktop only): changes when a placement tool is active.
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
              // Subtle page tint + opaque tap capture for placement tools.
              // HitTestBehavior.opaque is critical: it blocks pdfrx's parent
              // gesture recognizers from competing in the gesture arena.
              if (tool == AnnotationTool.addText ||
                  tool == AnnotationTool.addRect ||
                  tool == AnnotationTool.addHighlight)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _onBackgroundTap(context, ref, details.localPosition, scale),
                    child: isAddMode
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.indigoAccent.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                ),

              // Existing annotations
              for (final a in annotations)
                Positioned(
                  left: a.rect.x * scale,
                  top: a.rect.y * scale,
                  width: a.rect.width * scale,
                  height: a.rect.height * scale,
                  child: _AnnotationWidget(
                    key: ValueKey(a.id),
                    annotation: a,
                    scale: scale,
                    isSelected: a.id == selectedId,
                  ),
                ),

              // Live stroke drawing layer — on top of everything
              if (tool == AnnotationTool.addStroke)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.indigoAccent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: _StrokeDrawingLayer(page: page, scale: scale),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onBackgroundTap(
    BuildContext context,
    WidgetRef ref,
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
    const double defaultW = 200;
    const double defaultH = 50;
    final double clampedX = xPoints.clamp(0, page.width - defaultW);
    final double clampedY = yPoints.clamp(0, page.height - defaultH);
    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';

    if (tool == AnnotationTool.addText) {
      final text = await showAnnotationTextDialog(context, initialText: '');
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      if (text == null || text.trim().isEmpty) return;
      final style = ref.read(textStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.text(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedX, y: clampedY, width: defaultW, height: defaultH),
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
            rect: PageRect(x: clampedX, y: clampedY, width: defaultW, height: defaultH),
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
            rect: PageRect(x: clampedX, y: clampedY, width: defaultW, height: defaultH),
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
  });

  final Annotation annotation;
  final double scale;
  final bool isSelected;

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
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorArgb;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.001),
        border: isSelected
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: Color(colorArgb),
            height: 1.0,
          ),
        ),
      ),
    );
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
