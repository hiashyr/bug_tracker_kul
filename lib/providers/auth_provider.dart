import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:trying_flutter/services/yandex_auth.dart';

final authStateProvider = FutureProvider<User?>((ref) async {
  await YandexAuthService.init();
  return YandexAuthService.user;
});