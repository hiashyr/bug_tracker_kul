// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attachment _$AttachmentFromJson(Map<String, dynamic> json) => Attachment(
  id: json['id'] as String,
  name: json['name'] as String,
  display: Attachment._extractDisplay(
    json['createdBy'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$AttachmentToJson(Attachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdBy': Attachment._wrapDisplay(instance.display),
    };
