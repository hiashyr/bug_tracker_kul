import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

Future<String> generateJwtToken() async {
  // Загружаем переменные из .env
  await dotenv.load();

  // Логер для вывода информации в консоль
  final Logger _logger = Logger();
  
  final String serviceAccountId = dotenv.get('SERVICE_ACCOUNT_ID');
  final String serviceAccountTokenId = dotenv.get('SERVICE_ACCOUNT_TOKEN_ID');
  final String privateKey = dotenv.get('PRIVATE_KEY');
  
  // Проверяем, что все необходимые переменные загружены
  if (serviceAccountId.isEmpty || 
      serviceAccountTokenId.isEmpty || 
      privateKey.isEmpty) {
    throw Exception('Не все необходимые переменные окружения загружены');
  }
  
  // Текущее время в Unix timestamp (секунды)
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  
  // 1. Payload
  final payload = {
    'iss': serviceAccountId,
    'aud': 'https://iam.api.cloud.yandex.net/iam/v1/tokens',
    'iat': now,                         // Время создания токена
    'exp': now + 3600,                  // 3600 - 1 час, 600 - 10 минут
  };
  
  // 2. Header и сам JWT
  final jwt = JWT(
    payload,
    header: {
      'typ': 'JWT',
      'alg': 'PS256',
      'kid': serviceAccountTokenId,
    },
  );
  
  // 3. Подписываем токен приватным ключом
  final rsaPrivateKey = RSAPrivateKey(privateKey);
  final signedJwt = jwt.sign(rsaPrivateKey, algorithm: JWTAlgorithm.PS256);

  final _green = '\e[0;32m';
  final _magenta = '\x1B[35m';
  final _reset = '\x1B[0m';

  _logger.i('''
    ${_green}JWT токен успешно создан
    ${_magenta}Header: $_reset${signedJwt.split('.')[0]}
    ${_magenta}Payload: $_reset${signedJwt.split('.')[1]}
    ${_magenta}Signature: $_reset${signedJwt.split('.')[2]}
    ${_magenta}Полный JWT: $_reset$signedJwt
  ''');
  
  return signedJwt;
}

Future<Map<String, dynamic>> exchangeJwtForIamToken(String jwtToken) async {
  print('\n🔄 Обмениваем JWT на IAM-токен...');
  
  final url = Uri.parse('https://iam.api.cloud.yandex.net/iam/v1/tokens');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'jwt': jwtToken,
      }),
    );
    
    print('📡 Статус ответа: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      print('\n✅ IAM-токен успешно получен!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 Полный ответ от API:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Красиво форматируем вывод JSON
      final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
      print(prettyJson);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Извлекаем ключевые поля
      final iamToken = data['iamToken'];
      final expiresAt = data['expiresAt'];
      
      if (iamToken != null) {
        print('\n🔑 IAM токен: ${iamToken.substring(0, 50)}...');
        print('⏰ Действителен до: $expiresAt');
        
        // Декодируем время для удобства
        if (expiresAt != null) {
          final expiresDateTime = DateTime.parse(expiresAt);
          final remainingTime = expiresDateTime.difference(DateTime.now());
          print('⏳ Осталось времени: ${remainingTime.inHours} ч ${remainingTime.inMinutes.remainder(60)} мин');
        }
      }
      
      return data;
    } else {
      print('\n❌ Ошибка при обмене JWT на IAM-токен');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Статус код: ${response.statusCode}');
      print('Тело ответа: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('\n❌ Исключение при выполнении запроса:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print(e);
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    rethrow;
  }
}

// Дополнительная функция для получения только IAM токена (строка)
Future<String> getIamTokenString(String jwtToken) async {
  final data = await exchangeJwtForIamToken(jwtToken);
  return data['iamToken'] as String;
}

// Пример использования
void main() async {
  print('🚀 Запуск процесса получения IAM-токена\n');
  
  try {
    // 1. Генерируем JWT
    final jwtToken = await generateJwtToken();
    print('\n📝 Полный JWT токен:');
    print(jwtToken);
    
    // 2. Обмениваем на IAM-токен
    final response = await exchangeJwtForIamToken(jwtToken);
    
    // 3. Используем IAM-токен для дальнейших запросов
    final iamToken = response['iamToken'];
    
    // Пример: как использовать IAM-токен в заголовках
    print('\n💡 Пример использования IAM-токена:');
    print('Authorization: Bearer $iamToken');
    
    // Пример вызова другого API Яндекс.Облака
    // await callYandexCloudAPI(iamToken);
    
  } catch (e) {
    print('\n❌ Финальная ошибка: $e');
  }
}