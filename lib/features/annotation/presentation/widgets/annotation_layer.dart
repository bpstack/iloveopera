import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/annotation.dart';
import '../../domain/entities/page_rect.dart';
import '../providers/annotation_providers.dart';

/// Per-page overlay widget. Returned by [PdfViewerParams.pageOverlaysBuilder]
/// for every visible page; renders all annotations of that page on top of
/// pdfrx's own rendering.
///
/// The widget never computes screen/page transforms by hand — it uses
/// the page's bounding rect (the [LayoutBuilder] constraints) and the
/// page's intrinsic size in PDF points to derive a single scale factor.
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
        // pointsToScreen: render-box units per PDF point.
        final double scale = constraints.maxWidth <= 0
            ? 1.0
            : constraints.maxWidth / pageWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // Background gesture surface: only used in "add" modes to spawn
            // a new annotation at the tap point. Translucent so pan/zoom
            // still works for drags that start on the background.
            if (tool == AnnotationTool.addText || tool == AnnotationTool.addRect)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) => _onBackgroundTap(
                    ref,
                    details.localPosition,
                    scale,
                  ),
                ),
              ),
            for (final a in annotations)
              Positioned(
                left: a.rect.x * scale,
                top: a.rect.y * scale,
                width: a.rect.width * scale,
                height: a.rect.height * scale,
                child: _AnnotationWidget(
                  annotation: a,
                  scale: scale,
                  isSelected: a.id == selectedId,
                ),
              ),
          ],
        );
      },
    );
  }

  void _onBackgroundTap(WidgetRef ref, Offset localPosition, double scale) {
    final tool = ref.read(annotationToolProvider);
    if (tool == AnnotationTool.select) {
      ref.read(selectedAnnotationProvider.notifier).clear();
      return;
    }
    // Convert tap position to PDF points.
    final double xPoints = localPosition.dx / scale;
    final double yPoints = localPosition.dy / scale;
    const double defaultW = 200;
    const double defaultH = 50;
    // Keep the new rect inside the page bounds.
    final double clampedX = xPoints.clamp(0, page.width - defaultW);
    final double clampedY = yPoints.clamp(0, page.height - defaultH);

    final id = 'a-${DateTime.now().microsecondsSinceEpoch}';
    if (tool == AnnotationTool.addText) {
      final style = ref.read(textStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.text(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(
              x: clampedX,
              y: clampedY,
              width: defaultW,
              height: defaultH,
            ),
            text: 'Texto',
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            colorArgb: style.colorArgb,
          ));
    } else {
      final style = ref.read(rectStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.rect(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(
              x: clampedX,
              y: clampedY,
              width: defaultW,
              height: defaultH,
            ),
            colorArgb: style.colorArgb,
            opacity: style.opacity,
          ));
    }
    ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
    ref.read(selectedAnnotationProvider.notifier).set(id);
  }
}

class _AnnotationWidget extends ConsumerWidget {
  const _AnnotationWidget({
    required this.annotation,
    required this.scale,
    required this.isSelected,
  });

  final Annotation annotation;
  final double scale;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tool = ref.watch(annotationToolProvider);
    final canDrag = tool == AnnotationTool.select;

    final visual = switch (annotation) {
      TextAnnotation(:final fontFamily, :final fontSize, :final colorArgb, :final text) =>
        _TextAnnotationVisual(
          text: text,
          fontFamily: fontFamily,
          fontSize: fontSize,
          colorArgb: colorArgb,
          isSelected: isSelected,
        ),
      RectAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: isSelected,
        ),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(selectedAnnotationProvider.notifier).set(annotation.id),
      onPanStart: canDrag
          ? (_) => ref.read(selectedAnnotationProvider.notifier).set(annotation.id)
          : null,
      onPanUpdate: canDrag
          ? (details) {
              final dx = details.delta.dx / scale;
              final dy = details.delta.dy / scale;
              final current = annotation.rect;
              ref.read(annotationsProvider.notifier).moveLocal(
                    annotation.id,
                    current.copyWith(
                      x: current.x + dx,
                      y: current.y + dy,
                    ),
                  );
            }
          : null,
      child: visual,
    );
  }
}

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
        color: Colors.white.withValues(alpha: 0.001), // hit-testable but transparent
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
