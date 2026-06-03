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

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (tool == AnnotationTool.addText || tool == AnnotationTool.addRect)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) =>
                      _onBackgroundTap(context, ref, details.localPosition, scale),
                ),
              ),
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
          ],
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
      // Always return to select mode after attempting to add.
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
    } else {
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
    if (text == null) return; // cancelled
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
