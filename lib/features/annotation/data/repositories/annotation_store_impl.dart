import 'dart:convert';

import '../../domain/entities/annotation.dart';
import '../../domain/repositories/annotation_store.dart';

/// In-memory [AnnotationStore] with JSON (de)serialization for future
/// project persistence (Fase 5).
///
/// The list is the source of truth; JSON is just a transport format. The
/// store is **not** thread-safe; mutations must happen on the UI isolate.
class AnnotationStoreImpl implements AnnotationStore {
  final List<Annotation> _items = <Annotation>[];

  @override
  List<Annotation> listAll() => List<Annotation>.unmodifiable(_items);

  @override
  List<Annotation> listForPage(int pageNumber) {
    return _items.where((a) => a.pageNumber == pageNumber).toList(growable: false);
  }

  @override
  Annotation? getById(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  bool add(Annotation annotation) {
    if (_items.any((a) => a.id == annotation.id)) return false;
    _items.add(annotation);
    return true;
  }

  @override
  bool update(Annotation annotation) {
    final i = _items.indexWhere((a) => a.id == annotation.id);
    if (i < 0) return false;
    _items[i] = annotation;
    return true;
  }

  @override
  bool remove(String id) {
    final before = _items.length;
    _items.removeWhere((a) => a.id == id);
    return _items.length != before;
  }

  @override
  void clear() => _items.clear();

  @override
  String toJson() {
    final payload = <String, Object?>{
      'version': 1,
      'annotations': _items,
    };
    return jsonEncode(payload);
  }

  @override
  void loadFromJson(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('AnnotationStore JSON root must be an object.');
    }
    final list = raw['annotations'];
    if (list is! List) {
      throw const FormatException('AnnotationStore JSON missing "annotations" list.');
    }
    _items
      ..clear()
      ..addAll(list.map(
        (e) => Annotation.fromJson(Map<String, dynamic>.from(e as Map)),
      ));
  }
}
