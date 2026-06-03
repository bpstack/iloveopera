import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/font_registry/font_registry.dart';
import '../../data/repositories/annotation_store_impl.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/page_rect.dart';
import '../../domain/repositories/annotation_store.dart';
import '../../domain/usecases/add_annotation.dart';
import '../../domain/usecases/move_annotation.dart';
import '../../domain/usecases/remove_annotation.dart';
import '../../domain/usecases/update_annotation.dart';

/// Singleton annotation store for the current document. Replaced whenever
/// a new PDF is opened (see `viewer_screen.dart`).
final annotationStoreProvider = Provider<AnnotationStore>((ref) {
  final store = AnnotationStoreImpl();
  ref.onDispose(store.clear);
  return store;
});

final addAnnotationProvider = Provider<AddAnnotation>(
  (ref) => AddAnnotation(ref.watch(annotationStoreProvider)),
);
final updateAnnotationProvider = Provider<UpdateAnnotation>(
  (ref) => UpdateAnnotation(ref.watch(annotationStoreProvider)),
);
final moveAnnotationProvider = Provider<MoveAnnotation>(
  (ref) => MoveAnnotation(ref.watch(annotationStoreProvider)),
);
final removeAnnotationProvider = Provider<RemoveAnnotation>(
  (ref) => RemoveAnnotation(ref.watch(annotationStoreProvider)),
);

/// Current style for newly-created text annotations.
class TextStyleSpec {
  const TextStyleSpec({
    required this.fontFamily,
    required this.fontSize,
    required this.colorArgb,
  });

  final String fontFamily;
  final double fontSize;
  final int colorArgb;

  TextStyleSpec copyWith({String? fontFamily, double? fontSize, int? colorArgb}) =>
      TextStyleSpec(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
        colorArgb: colorArgb ?? this.colorArgb,
      );
}

class TextStyleNotifier extends Notifier<TextStyleSpec> {
  @override
  TextStyleSpec build() => const TextStyleSpec(
        fontFamily: 'Roboto',
        fontSize: 14,
        colorArgb: 0xFF000000,
      );

  void setFontFamily(String family) => state = state.copyWith(fontFamily: family);
  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void setColor(int argb) => state = state.copyWith(colorArgb: argb);
}

final textStyleProvider =
    NotifierProvider<TextStyleNotifier, TextStyleSpec>(TextStyleNotifier.new);

/// Current style for newly-created rect ("tipp-ex") annotations.
class RectStyleSpec {
  const RectStyleSpec({required this.colorArgb, required this.opacity});

  final int colorArgb;
  final double opacity;

  RectStyleSpec copyWith({int? colorArgb, double? opacity}) => RectStyleSpec(
        colorArgb: colorArgb ?? this.colorArgb,
        opacity: opacity ?? this.opacity,
      );
}

class RectStyleNotifier extends Notifier<RectStyleSpec> {
  @override
  RectStyleSpec build() => const RectStyleSpec(
        colorArgb: 0xFFFFFFFF,
        opacity: 1.0,
      );

  void setColor(int argb) => state = state.copyWith(colorArgb: argb);
  void setOpacity(double v) => state = state.copyWith(opacity: v);
}

final rectStyleProvider =
    NotifierProvider<RectStyleNotifier, RectStyleSpec>(RectStyleNotifier.new);

/// Tool currently active in the editor.
enum AnnotationTool { select, addText, addRect }

class AnnotationToolNotifier extends Notifier<AnnotationTool> {
  @override
  AnnotationTool build() => AnnotationTool.select;

  void set(AnnotationTool tool) => state = tool;
}

final annotationToolProvider =
    NotifierProvider<AnnotationToolNotifier, AnnotationTool>(AnnotationToolNotifier.new);

/// Currently selected annotation id, or `null` if none. Used to draw the
/// selection chrome and to delete via the keyboard / a button.
class SelectedAnnotationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
  void clear() => state = null;
}

final selectedAnnotationProvider =
    NotifierProvider<SelectedAnnotationNotifier, String?>(SelectedAnnotationNotifier.new);

/// Id of the text annotation currently being edited inline, or `null`.
/// Set when a text annotation is created or double-tapped; cleared on commit.
class EditingAnnotationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
  void clear() => state = null;
}

final editingAnnotationProvider =
    NotifierProvider<EditingAnnotationNotifier, String?>(EditingAnnotationNotifier.new);

/// Reactive list of all annotations in the open document.
class AnnotationsNotifier extends Notifier<List<Annotation>> {
  @override
  List<Annotation> build() {
    final store = ref.watch(annotationStoreProvider);
    final sub = store; // re-read on demand via the helper getter
    return sub.listAll();
  }

  void _refresh() => state = ref.read(annotationStoreProvider).listAll();

  void addLocal(Annotation a) {
    ref.read(addAnnotationProvider).call(a);
    _refresh();
  }

  void moveLocal(String id, PageRect newRect) {
    ref.read(moveAnnotationProvider).call(id, newRect);
    _refresh();
  }

  void updateLocal(Annotation a) {
    ref.read(updateAnnotationProvider).call(a);
    _refresh();
  }

  void removeLocal(String id) {
    ref.read(removeAnnotationProvider).call(id);
    if (ref.read(selectedAnnotationProvider) == id) {
      ref.read(selectedAnnotationProvider.notifier).clear();
    }
    _refresh();
  }

  /// Drop every annotation. Called when a new document is opened.
  void clearAll() {
    ref.read(annotationStoreProvider).clear();
    ref.read(selectedAnnotationProvider.notifier).clear();
    _refresh();
  }
}

final annotationsProvider =
    NotifierProvider<AnnotationsNotifier, List<Annotation>>(AnnotationsNotifier.new);

/// All annotations on a given page (1-based). Selector on top of the
/// list provider — used by the per-page overlay widget.
final annotationsForPageProvider = Provider.family<List<Annotation>, int>((ref, page) {
  return ref.watch(annotationsProvider).where((a) => a.pageNumber == page).toList();
});

/// Font catalog (ROADMAP §2.5) exposed to the UI.
final curadoFontsProvider = Provider<List<FontFamily>>((ref) => FontRegistry.curado);
