// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  login: json['login'] as String,
  display: json['display'] as String,
  email: json['email'] as String,
  cloudUid: json['cloudUid'] as String?,
  defaultAvatarId: json['default_avatar_id'] as String?,
  isAvatarEmpty: json['is_avatar_empty'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'login': instance.login,
  'display': instance.display,
  'email': instance.email,
  'cloudUid': instance.cloudUid,
  'default_avatar_id': instance.defaultAvatarId,
  'is_avatar_empty': instance.isAvatarEmpty,
};
