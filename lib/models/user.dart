import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String login;
  final String display;
  final String email;
  final String? cloudUid;
  
  @JsonKey(name: 'default_avatar_id')
  final String? defaultAvatarId;
  
  @JsonKey(name: 'is_avatar_empty')
  final bool isAvatarEmpty;

  User({
    required this.login,
    required this.display,
    required this.email,
    this.cloudUid,
    this.defaultAvatarId,
    this.isAvatarEmpty = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Геттер остается без изменений - это UI логика
  String? get avatarUrl {
    if (isAvatarEmpty) return null;
    final id = defaultAvatarId;
    if (id == null || id.isEmpty) return null;
    return 'https://avatars.yandex.net/get-yapic/$id/islands-50';
  }
}