import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Сервис для генерации JWT токенов сервисного аккаунта
class JwtService {
  final Logger _logger = Logger();

  static const Duration _tokenLifetime = Duration(minutes: 30);

  /// Генерирует подписанный JWT токен для сервисного аккаунта
  /// 
  /// Возвращает подписанный JWT токен в формате: header.payload.signature
  /// 
  /// Выбрасывает Exception если:
  /// - Не загружены переменные окружения
  /// - Приватный ключ некорректен
  Future<String> generateJwtToken() async {
    try {
      // Загружаем переменные из .env
      await dotenv.load();

      final String serviceAccountId = dotenv.get('SERVICE_ACCOUNT_ID');
      final String serviceAccountTokenId =
          dotenv.get('SERVICE_ACCOUNT_TOKEN_ID');
      final String privateKey = dotenv.get('PRIVATE_KEY');

      // Проверяем, что все необходимые переменные загружены
      if (serviceAccountId.isEmpty ||
          serviceAccountTokenId.isEmpty ||
          privateKey.isEmpty) {
        throw Exception(
          'Не все необходимые переменные окружения загружены: '
          'SERVICE_ACCOUNT_ID, SERVICE_ACCOUNT_TOKEN_ID, PRIVATE_KEY',
        );
      }

      // Текущее время в Unix timestamp (секунды)
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Формируем payload JWT
      final payload = {
        'iss': serviceAccountId,
        'aud': 'https://iam.api.cloud.yandex.net/iam/v1/tokens',
        'iat': now, // Время создания токена
        'exp': now + _tokenLifetime.inSeconds, // Время истечения
      };

      // Создаём JWT с заголовком
      final jwt = JWT(
        payload,
        header: {
          'typ': 'JWT',
          'alg': 'PS256',
          'kid': serviceAccountTokenId,
        },
      );

      // Подписываем токен приватным ключом
      final rsaPrivateKey = RSAPrivateKey(privateKey);
      final signedJwt =
          jwt.sign(rsaPrivateKey, algorithm: JWTAlgorithm.PS256);

      _logJwtGeneration(signedJwt);

      return signedJwt;
    } catch (e) {
      _logger.e('Ошибка при генерации JWT: $e');
      rethrow;
    }
  }

  /// Логирует информацию о созданном JWT токене
  void _logJwtGeneration(String signedJwt) {
    const magenta = '\x1B[35m';
    const green = '\x1B[32m';
    const reset = '\x1B[0m';

    final parts = signedJwt.split('.');
    if (parts.length == 3) {
      _logger.d('''
        $green✓ JWT токен успешно создан$reset

        ${magenta}Header:$reset ${parts[0]}
        ${magenta}Payload:$reset ${parts[1]}
        ${magenta}Signature:$reset ${parts[2]}
      ''');
    }
  }
}

/// Глобальный провайдер для JwtService
final jwtServiceProvider = JwtService();