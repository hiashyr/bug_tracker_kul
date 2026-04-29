import 'package:logger/logger.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart';
import 'api_client.dart';

class YandexAuthService {
  static const String clientId = '500a9873ee2c4f5b83553ae164b5bab6';
  static const String redirectUri = 'http://localhost:62044';
  static const String scopes = 'tracker:read tracker:write login:avatar';

  static final Logger _logger = Logger();

  static Future<void> loginWithYandex() async {
    _logger.i('Начинаем процесс авторизации через Яндекс');
    final authUrl =
        'https://oauth.yandex.ru/authorize?response_type=token&client_id=$clientId&redirect_uri=$redirectUri&scope=$scopes';

    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl), webOnlyWindowName: '_self');
      _logger.i('URL авторизации открыт успешно');
    } else {
      _logger.e('Не удалось открыть URL авторизации');
      throw 'Не удалось открыть URL авторизации';
    }
  }

  static Future<void> handleAuthCallback(String hash) async {
      try {
        final params = _parseHash(hash);
        _accessToken = params['access_token'];
        _logger.i('Токен получен: $_accessToken');
        await _saveTokenToStorage(_accessToken!);
        _logger.i('Токен сохранен: $_accessToken');
      } catch (e) {
        _logger.e('Ошибка обработки OAuth callback: $e');
      }
  }

  static Future<void> init() async {
    _logger.i('Инициализация YandexAuthService');
    final hash = window.location.hash;
    if (hash.contains('access_token')) {
      _logger.i("Обнаружен hash с access_token, запускаем handleAuthCallback(hash)");
        await handleAuthCallback(hash);
      } else {
        _logger.i("Hash не содержит access_token, пропускаем обработку callback");
      }
    _accessToken = await loadTokenFromStorage();
    if (_accessToken != null) {
      _logger.i('Токен загружен из хранилища');
      try {
        // Используем ApiClient метод
        final apiClient = ApiClient();
        _user = await apiClient.fetchCurrentUser();
        _logger.i('Пользователь восстановлен: ${_user?.display}');
      } catch (e) {
        _logger.e('Ошибка восстановления пользователя: $e');
        _accessToken = null;
        _user = null;
      }
    } else {
      _logger.i('Токен не найден в хранилище');
    }
  }

  static Future<void> logout() async {
    _logger.i('Выход из аккаунта');
    _accessToken = null;
    _user = null;
    window.localStorage.removeItem('yandex_access_token');
    _logger.i('Токен удален из хранилища');
  }

  static String? _accessToken;
  static User? _user;

  static String? get accessToken => _accessToken;
  static User? get user => _user;

  static Map<String, String> _parseHash(String hash) {
    final params = <String, String>{};
    final query = hash.startsWith('#') ? hash.substring(1) : hash;
    for (final pair in query.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        params[parts[0]] = Uri.decodeComponent(parts[1]);
      }
    }
    return params;
  }

  static Future<void> _saveTokenToStorage(String token) async {
    window.localStorage.setItem('yandex_access_token', token);
  }

  static Future<String?> loadTokenFromStorage() async {
    return window.localStorage.getItem('yandex_access_token');
  }
}