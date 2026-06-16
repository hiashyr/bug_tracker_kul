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
  
  User({
    required this.login,
    required this.display,
    required this.email,
    this.cloudUid,
    this.defaultAvatarId,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Формирует URL аватара из default_avatar_id, полученного от Яндекс ID
  String? get avatarUrl {
    final id = defaultAvatarId;
    if (id == null || id.isEmpty) return null;
    return 'https://avatars.yandex.net/get-yapic/$id/islands-50';
  }
}