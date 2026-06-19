// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
  id: json['id'] as String,
  name: json['name'] as String,
  content: json['content'] as String,
  thumbnail: json['thumbnail'] as String?,
  display: Attachment._extractDisplay(
    json['createdBy'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'content': instance.content,
      'thumbnail': instance.thumbnail,
      'createdBy': Attachment._wrapDisplay(instance.display),
    };
