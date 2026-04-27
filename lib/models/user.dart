class User {
  final String login;
  final String display;
  final String email;
  final String? cloudUid; // Уникальный идентификатор пользователя в облаке, будет null для ботов
  
  final String? defaultAvatarId;
  final bool isAvatarEmpty;

  User({
    required this.login,
    required this.display,
    required this.email,
    this.cloudUid,

    this.defaultAvatarId,
    this.isAvatarEmpty = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      login: json['login'],
      display: json['display'],
      email: json['email'],
      cloudUid: json['cloudUid'],

      defaultAvatarId: json['default_avatar_id'],
      isAvatarEmpty: json['is_avatar_empty'] ?? false,
    );
  }

  String? get avatarUrl {
    if (isAvatarEmpty) return null;
    final id = defaultAvatarId;
    if (id == null || id.isEmpty) return null;
    return 'https://avatars.yandex.net/get-yapic/$id/islands-50';
  }
}