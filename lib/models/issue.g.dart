// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Issue _$IssueFromJson(Map<String, dynamic> json) => Issue(
  id: json['id'] as String,
  self: json['self'] as String,
  summary: json['summary'] as String?,
  description: json['description'] as String?,
  status: Issue._extractDisplay(json['status'] as Map<String, dynamic>?),
  priority: Issue._extractDisplay(json['priority'] as Map<String, dynamic>?),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  createdBy: Issue._extractDisplay(json['createdBy'] as Map<String, dynamic>?),
  qaEngineer: Issue._extractDisplayNullable(
    json['qaEngineer'] as Map<String, dynamic>?,
  ),
);

Map<String, dynamic> _$IssueToJson(Issue instance) => <String, dynamic>{
  'id': instance.id,
  'self': instance.self,
  'summary': instance.summary,
  'description': instance.description,
  'status': Issue._wrapDisplay(instance.status),
  'priority': Issue._wrapDisplay(instance.priority),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'createdBy': Issue._wrapDisplay(instance.createdBy),
  'qaEngineer': Issue._wrapDisplayNullable(instance.qaEngineer),
};
