import 'package:freezed_annotation/freezed_annotation.dart';

import 'page_rect.dart';

part 'annotation.freezed.dart';
part 'annotation.g.dart';

/// Sealed union of annotation types supported by the app.
///
/// Fase 2 only ships [Annotation.text] and [Annotation.rect]; more variants
/// will be added in later phases (Stroke, Highlight, etc.) following the
/// same pattern.
@freezed
sealed class Annotation with _$Annotation {
  const Annotation._();

  /// Free-form text drawn on top of a page. Color is stored as a 32-bit
  /// ARGB integer so the domain layer has no Flutter dependency.
  const factory Annotation.text({
    required String id,
    required int pageNumber,
    required PageRect rect,
    required String text,
    required String fontFamily,
    required double fontSize,
    required int colorArgb,
  }) = TextAnnotation;

  /// Opaque rectangle ("tipp-ex"): used to mask parts of the original page
  /// before drawing on top.
  const factory Annotation.rect({
    required String id,
    required int pageNumber,
    required PageRect rect,
    required int colorArgb,
    @Default(1.0) double opacity,
  }) = RectAnnotation;

  /// JSON factory used by [json_serializable] to round-trip the sealed
  /// union. The generated `_$AnnotationFromJson` is produced by
  /// `build_runner`.
  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);
}
