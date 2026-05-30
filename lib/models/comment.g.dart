// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  text: json['text'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  createdBy: Comment._extractDisplay(
    json['createdBy'] as Map<String, dynamic>?,
  ),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  updatedBy: Comment._extractDisplayNullable(
    json['updatedBy'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'text': instance.text,
  'createdAt': instance.createdAt.toIso8601String(),
  'createdBy': Comment._wrapDisplay(instance.createdBy),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'updatedBy': Comment._wrapDisplayNullable(instance.updatedBy),
};
