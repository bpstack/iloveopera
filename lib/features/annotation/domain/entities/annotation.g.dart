// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAnnotation _$TextAnnotationFromJson(Map<String, dynamic> json) =>
    TextAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      text: json['text'] as String,
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      colorArgb: (json['colorArgb'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$TextAnnotationToJson(TextAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'rect': instance.rect,
      'text': instance.text,
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
      'colorArgb': instance.colorArgb,
      'runtimeType': instance.$type,
    };

RectAnnotation _$RectAnnotationFromJson(Map<String, dynamic> json) =>
    RectAnnotation(
      id: json['id'] as String,
      pageNumber: (json['pageNumber'] as num).toInt(),
      rect: PageRect.fromJson(json['rect'] as Map<String, dynamic>),
      colorArgb: (json['colorArgb'] as num).toInt(),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$RectAnnotationToJson(RectAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageNumber': instance.pageNumber,
      'rect': instance.rect,
      'colorArgb': instance.colorArgb,
      'opacity': instance.opacity,
      'runtimeType': instance.$type,
    };
