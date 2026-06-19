import 'package:json_annotation/json_annotation.dart';

part 'attachment.g.dart';

@JsonSerializable()
class Attachment {
  final String id;
  final String name;

  @JsonKey(name: 'createdBy', fromJson: _extractDisplay, toJson: _wrapDisplay)
  final String display;

  Attachment({
    required this.id,
    required this.name,
    required this.display,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$AttachmentToJson(this);

  // Хелперы для конвертации {display: ...}
  static String _extractDisplay(Map<String, dynamic>? json) {
    return json?['display'] as String? ?? '';
  }

  static Map<String, dynamic> _wrapDisplay(String value) {
    return {'display': value};
  }
}
