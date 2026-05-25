import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/yandex_auth.dart';

class AuthAuthorizer extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // При инициализации провайдера:
    // - восстанавливаем состояние по токену (если есть, считаем успешный вход)
    // - можно optionally проверить сессию
    return YandexAuthService.accessToken != null;
  }

  // Логин через Яндекс
  Future<void> login() async {
    state = const AsyncValue.loading(); // UI покажет loading

    try {
      final success = await YandexAuthService.loginWithYandex();
      state = AsyncValue.data(success); // UI получит true/false
    } on Exception catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Выход
  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await YandexAuthService.logout();
      // После logout состояние = false (не авторизован)
      state = const AsyncValue.data(false);
    } on Exception catch (e, stack) {
      // Вернём ошибочное состояние
      state = AsyncValue.error(e, stack);
    }
  }

  // Опционально: ручное обновление сессии (например, при старте приложения)
  Future<void> restoreSession() async {
    final hasToken = YandexAuthService.accessToken != null;
    state = AsyncValue.data(hasToken);
  }
}

// Сам провайдер, который будет использоваться в UI
final authAuthorizerProvider =
    AsyncNotifierProvider<AuthAuthorizer, bool>(AuthAuthorizer.new);

final isAuthorizedProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authAuthorizerProvider);
  return authAsync.when(
    data: (bool) => bool,
    loading: () => false,
    error: (_, __) => false,
  );
});