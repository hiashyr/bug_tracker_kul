import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:logger/logger.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:web/web.dart';
import 'api_client.dart';

class YandexAuthService {
  static const String clientId = '500a9873ee2c4f5b83553ae164b5bab6';
  static const String redirectUri = 'http://localhost:62044/auth.html';
  static const String scopes = 'tracker:read tracker:write login:avatar';

  static final Logger _logger = Logger();

  static Future<bool> loginWithYandex() async {
    _logger.i('Начинаем процесс авторизации через Яндекс');
    final authUrl =
        'https://oauth.yandex.ru/authorize?response_type=token&client_id=$clientId&redirect_uri=$redirectUri&scope=$scopes';

    final fullAuthUrl = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'http',
      options: const FlutterWebAuth2Options(
        httpsHost: 'localhost',
        httpsPath: '/auth.html',
      ),
    );
    final success = await handleAuthCallback(fullAuthUrl);
    return success;
  }

  static Future<bool> handleAuthCallback(String fullUrl) async {
    _logger.i('Обработка OAuth callback: $fullUrl');
    try {
      final uri = Uri.parse(fullUrl);
      final fragment = uri.fragment;
      final params = _parseHash(fragment);

      _accessToken = params['access_token'];
      _logger.i('Токен получен: $_accessToken');
      if (_accessToken != null) {
          await getUserInfo();
        _saveTokenToStorage(_accessToken!);
        _logger.i('Токен сохранен: $_accessToken');
      return true;
    } else {
      _logger.w('[AUTH] token not found');
      return false;
    }
  } catch (e) {
      _logger.e('Ошибка при обработке OAuth callback: $e');
      return false;
    }
  }

  static Future<void> init() async {
    _logger.i('Инициализация YandexAuthService');

    _accessToken = await loadTokenFromStorage();
    if (_accessToken != null) {
      _logger.i('Токен загружен из хранилища');

      await getUserInfo();
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

  static Future<void> getUserInfo() async {
    if (_accessToken == null) {
      _logger.w('Нет токена для обновления пользователя');
      return;
    } else {
        try {
          final apiClient = ApiClient();
          _user = await apiClient.fetchCurrentUser();
          _logger.i('Пользователь получен: ${_user?.display}');
        } catch (e) {
          _logger.e('Ошибка при получении данных пользователя: $e');
        }
    }
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