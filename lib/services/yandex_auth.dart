import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

class YandexAuthService {
  static const String clientId = 'a74eee4c0faa43578ed9f16f39016fe8';
  static const String redirectUri = 'https://oauth.yandex.ru/verification_code'; // Для локальной разработки; замените на ваш домен в продакшене
  static const String scopes = 'tracker:read tracker:write';

  static final Logger _logger = Logger();

  static Future<void> loginWithYandex() async {
    _logger.i('Начинаем процесс авторизации через Яндекс');
    final authUrl = 'https://oauth.yandex.ru/authorize?response_type=token&client_id=$clientId&redirect_uri=$redirectUri&scope=$scopes';

    if (await canLaunchUrl(Uri.parse(authUrl))) {
      _logger.i('Открываем URL авторизации: $authUrl');
      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      _logger.i('URL авторизации открыт успешно');
    } else {
      _logger.e('Не удалось открыть URL авторизации');
      throw 'Не удалось открыть URL авторизации';
    }
  }

  static Future<void> handleAuthCallback(String hash) async {
    _logger.i('Обрабатываем callback с hash: $hash');
    final params = _parseHash(hash);
    if (params.containsKey('access_token')) {
      _accessToken = params['access_token'];
      _logger.i('Токен получен и сохранен');
      await _saveTokenToStorage(_accessToken!);
      _user = await fetchCurrentUser();
      _logger.i('Пользователь получен: ${_user?['display']}');
    } else {
      _logger.e('Токен не найден в hash');
      throw 'Токен не найден в URL';
    }
  }

  static Future<void> init() async {
    _logger.i('Инициализация YandexAuthService');
    _accessToken = await loadTokenFromStorage();
    if (_accessToken != null) {
      _logger.i('Токен загружен из хранилища');
      try {
        _user = await fetchCurrentUser();
        _logger.i('Пользователь восстановлен: ${_user?['display']}');
      } catch (e) {
        _logger.e('Ошибка восстановления пользователя: $e');
        _accessToken = null;
        _user = null;
      }
    } else {
      _logger.i('Токен не найден в хранилище');
    }
  }

  static Future<Map<String, dynamic>> fetchCurrentUser() async {
    if (_accessToken == null) {
      _logger.e('Токен отсутствует для запроса пользователя');
      throw 'Токен не найден';
    }

    _logger.i('Запрашиваем данные текущего пользователя');
    final response = await http.get(
      Uri.parse('https://api.tracker.yandex.net/v2/myself'),
      headers: {'Authorization': 'OAuth $_accessToken'},
    );

    if (response.statusCode == 200) {
      _logger.i('Данные пользователя получены успешно');
      return json.decode(response.body);
    } else {
      _logger.e('Ошибка получения пользователя: ${response.statusCode} - ${response.body}');
      throw 'Ошибка получения пользователя: ${response.statusCode}';
    }
  }

  static Future<void> logout() async {
    _logger.i('Выход из аккаунта');
    _accessToken = null;
    _user = null;
    html.window.localStorage.remove('yandex_access_token');
    _logger.i('Токен удален из хранилища');
  }

  static String? _accessToken;
  static Map<String, dynamic>? _user;

  static String? get accessToken => _accessToken;
  static Map<String, dynamic>? get user => _user;

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
    html.window.localStorage['yandex_access_token'] = token;
  }

  static Future<String?> loadTokenFromStorage() async {
    return html.window.localStorage['yandex_access_token'];
  }
}