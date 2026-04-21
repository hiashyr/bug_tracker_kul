class IamToken {
  final String token;
  final DateTime expiresAt;

  IamToken({
    required this.token,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}