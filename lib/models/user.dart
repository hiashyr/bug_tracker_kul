class User {
  final String login;
  final String display;
  final String email;
  final String? cloudUid; // Уникальный идентификатор пользователя в облаке, будет null для ботов

  User({
    required this.login,
    required this.display,
    required this.email,
    this.cloudUid,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      login: json['login'],
      display: json['display'],
      email: json['email'],
      cloudUid: json['cloudUid']
    );
  }
}