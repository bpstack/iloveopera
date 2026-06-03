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
/// The widget never computes screen/page transforms by hand — it uses the
/// page's bounding rect (the [LayoutBuilder] constraints) and the page's
/// intrinsic size in PDF points to derive a single scale factor (R5).
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
                      _onBackgroundTap(ref, details.localPosition, scale),
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

  void _onBackgroundTap(WidgetRef ref, Offset localPosition, double scale) {
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
      final style = ref.read(textStyleProvider);
      ref.read(annotationsProvider.notifier).addLocal(Annotation.text(
            id: id,
            pageNumber: page.pageNumber,
            rect: PageRect(x: clampedX, y: clampedY, width: defaultW, height: defaultH),
            text: '',
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            colorArgb: style.colorArgb,
          ));
      ref.read(annotationToolProvider.notifier).set(AnnotationTool.select);
      ref.read(selectedAnnotationProvider.notifier).set(id);
      // Start editing immediately so the user can type.
      ref.read(editingAnnotationProvider.notifier).set(id);
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

/// A single annotation, positioned and interactive.
///
/// Dragging is handled with LOCAL state (a temporary screen-space offset) and
/// committed to the store only on pan end — this avoids rebuilding the whole
/// overlay on every pointer move (the cause of the earlier jank). Text
/// annotations switch to an inline editor while their id is in
/// [editingAnnotationProvider].
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

  void _commitText(String value) {
    final a = widget.annotation;
    final text = value.trim();
    if (text.isEmpty) {
      // An empty text annotation is discarded.
      ref.read(annotationsProvider.notifier).removeLocal(a.id);
    } else if (a is TextAnnotation) {
      ref.read(annotationsProvider.notifier).updateLocal(a.copyWith(text: text));
    }
    ref.read(editingAnnotationProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(annotationToolProvider);
    final editingId = ref.watch(editingAnnotationProvider);
    final a = widget.annotation;
    final scale = widget.scale;
    final isEditing = a is TextAnnotation && editingId == a.id;
    final canDrag = tool == AnnotationTool.select && !isEditing;

    final Widget visual = switch (a) {
      TextAnnotation(:final fontFamily, :final fontSize, :final colorArgb, :final text) =>
        _TextAnnotationVisual(
          text: text,
          fontFamily: fontFamily,
          fontSize: fontSize * scale,
          colorArgb: colorArgb,
          isSelected: widget.isSelected,
          isEditing: isEditing,
          onCommit: _commitText,
        ),
      RectAnnotation(:final colorArgb, :final opacity) => _RectAnnotationVisual(
          colorArgb: colorArgb,
          opacity: opacity,
          isSelected: widget.isSelected,
        ),
    };

    // The committed position is applied by the parent Positioned; the
    // in-progress drag is a local visual translation (no store writes per
    // frame). transformHitTests keeps the hit area under the cursor.
    return Transform.translate(
      offset: _drag,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(selectedAnnotationProvider.notifier).set(a.id),
        onDoubleTap: a is TextAnnotation
            ? () {
                ref.read(selectedAnnotationProvider.notifier).set(a.id);
                ref.read(editingAnnotationProvider.notifier).set(a.id);
              }
            : null,
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
    required this.isEditing,
    required this.onCommit,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int colorArgb;
  final bool isSelected;
  final bool isEditing;
  final ValueChanged<String> onCommit;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: Color(colorArgb),
      height: 1.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.001),
        border: (isSelected || isEditing)
            ? Border.all(color: Colors.indigoAccent, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: isEditing
          ? _TextEditor(initialText: text, style: textStyle, onCommit: onCommit)
          : Align(
              alignment: Alignment.topLeft,
              child: Text(text, style: textStyle),
            ),
    );
  }
}

/// Inline text editor shown while a text annotation is being edited.
class _TextEditor extends StatefulWidget {
  const _TextEditor({
    required this.initialText,
    required this.style,
    required this.onCommit,
  });

  final String initialText;
  final TextStyle style;
  final ValueChanged<String> onCommit;

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      maxLines: null,
      expands: false,
      cursorColor: Colors.indigoAccent,
      style: widget.style,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: 'Escribe…',
      ),
      // Commit when the user clicks elsewhere; keeps multi-line input working.
      onTapOutside: (_) => widget.onCommit(_controller.text),
      onSubmitted: (_) => widget.onCommit(_controller.text),
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
