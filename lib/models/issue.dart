import 'package:json_annotation/json_annotation.dart';

part 'issue.g.dart';

@JsonSerializable()
class Issue {
  final String id;
  final String self;
  final String? summary;
  final String? description;
  
  @JsonKey(name: 'status', fromJson: _extractDisplay, toJson: _wrapDisplay)
  final String status;
  
  @JsonKey(name: 'priority', fromJson: _extractDisplay, toJson: _wrapDisplay)
  final String priority;
  
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  @JsonKey(name: 'createdBy', fromJson: _extractDisplay, toJson: _wrapDisplay)
  final String createdBy;
  
  @JsonKey(name: 'qaEngineer', fromJson: _extractDisplayNullable, toJson: _wrapDisplayNullable)
  final String? qaEngineer;

  Issue({
    required this.id,
    required this.self,
    required this.summary,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.qaEngineer,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
  Map<String, dynamic> toJson() => _$IssueToJson(this);

  // Хелперы для конвертации {display: ...}
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