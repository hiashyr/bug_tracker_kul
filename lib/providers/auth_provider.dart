import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/models/iam_token.dart';

import '../services/api_client.dart';
import '../services/jwt_service.dart';

/// Провайдер для JwtService
/// Используется для генерации JWT токенов
final jwtServiceProvider = Provider<JwtService>((ref) {
  return JwtService();
});

/// Основной провайдер для получения и кэширования IAM токена
///
/// Это провайдер выполняет оба шага авторизации:
/// 1. Генерирует JWT токен через JwtService
/// 2. Обменивает JWT на IAM-токен через ApiClient
///
/// Результат автоматически кэшируется до истечения токена
final iamTokenProvider = FutureProvider<IamToken>((ref) async {
  final jwtService = ref.watch(jwtServiceProvider);
  final apiClient = ref.watch(apiClientProvider);

  // Генерируем JWT токен
  final jwtToken = await jwtService.generateJwtToken();

  // Обмениваем JWT на IAM-токен
  return await apiClient.exchangeJwtForIamToken(jwtToken);
});

/// Провайдер для получения IAM-токена как строки для заголовков
///
/// Используйте этот провайдер, когда нужна строка "Bearer {token}"
/// для добавления в заголовок Authorization

final iamTokenHeaderProvider = FutureProvider<String>((ref) async {
  final iamToken = await ref.watch(iamTokenProvider.future);
  return 'Bearer ${iamToken.token}';
});

/// Провайдер для проверки, валиден ли текущий IAM-токен
///
/// Возвращает true если токен ещё действителен
/// Возвращает false если токен истёк или его нет
/// 
final isIamTokenValidProvider = FutureProvider<bool>((ref) async {
  try {
    final iamToken = await ref.watch(iamTokenProvider.future);
    return !iamToken.isExpired;
  } catch (e) {
    return false;
  }
});
