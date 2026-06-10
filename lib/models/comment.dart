import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final String id;
  final String text;
  final DateTime createdAt;
  
  @JsonKey(name: 'createdBy', fromJson: _extractDisplay, toJson: _wrapDisplay)
  final String createdBy;
  
  final DateTime? updatedAt;
  
  @JsonKey(name: 'updatedBy', fromJson: _extractDisplayNullable, toJson: _wrapDisplayNullable)
  final String? updatedBy;

  Comment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  // Хелперы для конвертации вложенных объектов {display: ...}
  static String _extractDisplay(Map<String, dynamic>? json) {
    return json?['display'] as String? ?? '';
  }

  static String? _extractDisplayNullable(Map<String, dynamic>? json) {
    return json?['display'] as String?;
  }

  static Map<String, dynamic> _wrapDisplay(String value) {
    return {'display': value};
  }

  static Map<String, dynamic>? _wrapDisplayNullable(String? value) {
    return value != null ? {'display': value} : null;
  }
}