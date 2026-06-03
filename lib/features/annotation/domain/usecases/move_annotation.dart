import '../entities/annotation.dart';
import '../entities/page_rect.dart';
import '../repositories/annotation_store.dart';

class MoveAnnotation {
  const MoveAnnotation(this._store);
  final AnnotationStore _store;

  /// Move the annotation with [id] to the given page-relative rect.
  /// Returns `false` if the id is unknown.
  bool call(String id, PageRect newRect) {
    final existing = _store.getById(id);
    if (existing == null) return false;
    final moved = switch (existing) {
      TextAnnotation() => existing.copyWith(rect: newRect),
      RectAnnotation() => existing.copyWith(rect: newRect),
    };
    return _store.update(moved);
  }
}
