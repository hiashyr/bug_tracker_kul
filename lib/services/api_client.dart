import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trying_flutter/models/user.dart';
import 'package:trying_flutter/services/logging.dart';

import '../models/comment.dart';
import '../models/issue.dart';
import '../models/status.dart';
import '../services/api_exceptions.dart';
import '../services/yandex_auth.dart';

class ApiClient {
  final String baseUrl = 'https://api.tracker.yandex.net/v3';
  final String _orgId = dotenv.get('ORG_ID');
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? LoggingClient();

  static const Duration _requestTimeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
    'Authorization': 'OAuth ${YandexAuthService.accessToken}',
    'Content-Type': 'application/json',
    'Host': 'api.tracker.yandex.net',
    'X-Cloud-Org-Id': _orgId,
  };

  static const Map<String, List<String>> _transitionRequiredFields = {
    // Пример, если бы у некоторых переходов были обязательные поля
    // 'transition_to_review': ['reviewerComment', 'reviewReason'],
    // 'transition_done': ['closedReason'],
    'testing': [
      'qaEngineer',
    ], // Это поле принимает username из запроса. Сущность User
    'needInfo': ['pendingReplyFrom'], // Также принимает username из запроса.
  };

  // Запрос на получение пользователей
  Future<List<User>> fetchUsers() async {
    return _request(
      () => _client.get(Uri.parse('$baseUrl/users'), headers: _headers),
      200,
      (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      action: 'получение пользователей',
    );
  }

  // Запрос на получение конкретного пользователя
  Future<User> fetchCurrentUser() async {
    return _request(
      () => _client.get(Uri.parse('$baseUrl/myself'), headers: _headers),
      200,
      (json) => User.fromJson(json as Map<String, dynamic>),
      action: 'получение текущего пользователя',
    );
  }

  // Запрос на переход в статус с полями. Поля берем из _transitionRequiredFields
  Future<void> statusTransition(
    String issueId,
    String transitionId, {
    Map<String, dynamic> fieldValues = const {},
  }) async {
    final payload = _buildTransitionPayload(transitionId, fieldValues);

    try {
      final response = await _client.post(
        Uri.parse(
          '$baseUrl/issues/$issueId/transitions/$transitionId/_execute',
        ),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Ошибка при переходе в статус: ${response.reasonPhrase ?? 'неверный ответ'}',
          url: response.request?.url.toString() ?? baseUrl,
          details: _extractErrorMessage(response),
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('Нет соединения при переходе в статус', originalException: e);
    } on TimeoutException catch (e) {
      throw NetworkException('Таймаут при переходе в статус', originalException: e);
    } on http.ClientException catch (e) {
      throw NetworkException('Ошибка HTTP при переходе в статус: ${e.message}', originalException: e);
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Непредвиденная ошибка при переходе в статус',
        url: baseUrl,
        details: e.toString(),
      );
    }
  }

  Map<String, dynamic> _buildTransitionPayload(
    String transitionId, [
    Map<String, dynamic> fieldValues = const {},
  ]) {
    final requiredFields = _transitionRequiredFields[transitionId];
    if (requiredFields == null || requiredFields.isEmpty) {
      return {};
    }

    return {for (final field in requiredFields) field: fieldValues[field]};
  }

  // Метод для получения одной задачи по ID
  Future<Issue> fetchIssue(String issueId) async {
    return _request(
      () =>
          _client.get(Uri.parse('$baseUrl/issues/$issueId'), headers: _headers),
      200,
      (json) => Issue.fromJson(json as Map<String, dynamic>),
      action: 'получение задачи',
    );
  }

  // Метод для получения статусов, в которые задача может перейти
  Future<List<Status>> fetchStatuses(String issueId) async {
    return _request(
      () => _client.get(
        Uri.parse('$baseUrl/issues/$issueId/transitions'),
        headers: _headers,
      ),
      200,
      (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => Status.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      action: 'получение статусов',
    );
  }

  // Методя для получения комментариев задачи
  Future<List<Comment>> fetchComments(String issueId) async {
    return _request(
      () => _client.get(
        Uri.parse('$baseUrl/issues/$issueId/comments'),
        headers: _headers,
      ),
      200,
      (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => Comment.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      action: 'получение комментариев',
    );
  }

  // Метод для добавления комментария к задаче
  Future<Comment> addingComment(String issueId, String commentText) async {
    return _request(
      () => _client.post(
        Uri.parse('$baseUrl/issues/$issueId/comments'),
        headers: _headers,
        body: jsonEncode({'text': commentText}),
      ),
      201,
      (json) => Comment.fromJson(json as Map<String, dynamic>),
      action: 'добавление комментария',
    );
  }

  // Метод для получения списка задач по статусу "Можно тестировать"
  Future<List<Issue>> showIssues() async {
    return _request(
      () => _client.post(
        Uri.parse('$baseUrl/issues/_search?expand=transitions'),
        headers: _headers,
        body: jsonEncode({
          'filter': {'queue': 'DEV', 'status': 'readyForTest'},
          'order': '+status',
        }),
      ),
      200,
      (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => Issue.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      action: 'получение списка задач',
    );
  }

  // Получение ID аватарки пользователя из Яндекс профиля
  Future<String?> fetchUserAvatarId() async {
    return _request(
      () => _client.get(
        Uri.parse('https://login.yandex.ru/info?format=json'),
        headers: {'Authorization': 'OAuth ${YandexAuthService.accessToken}'},
      ),
      200,
      (json) {
        final map = json as Map<String, dynamic>;
        // Не забываем что у пользвоателя может быть дефолт ава
        final isEmpty = map['is_avatar_empty'] as bool? ?? false;
        final avatarId = map['default_avatar_id'] as String?;
        if (isEmpty || avatarId == null || avatarId.isEmpty) return null;
        return avatarId;
      },
      action: 'получение ID аватарки',
    );
  }

  // Универсальный generic метод для всех API запросов
  Future<T> _request<T>(
    Future<http.Response> Function() requestFn,
    int expectedStatus,
    T Function(dynamic json) parser, {
    required String action,
  }) async {
    try {
      final response = await requestFn().timeout(_requestTimeout);

      // Валидация статуса ответа
      if (response.statusCode != expectedStatus) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Ошибка при $action: ${response.reasonPhrase ?? 'неверный ответ'}',
          url: response.request?.url.toString() ?? baseUrl,
          details: _extractErrorMessage(response),
        );
      }

      // Парсинг JSON ответа
      try {
        final decoded = jsonDecode(response.body);
        return parser(decoded);
      } on FormatException {
        throw JsonParsingException('Ошибка разбора JSON при $action', response.body);
      }
    } on SocketException catch (e) {
      throw NetworkException(
        'Нет соединения при $action',
        originalException: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        'Таймаут при $action',
        originalException: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Ошибка HTTP при $action: ${e.message}',
        originalException: e,
      );
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on JsonParsingException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Непредвиденная ошибка при $action',
        url: baseUrl,
        details: e.toString(),
      );
    }
  }

  // Метод для извлечения сообщения об ошибке из тела ответа
  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Пустое тело ответа';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            response.body;
      }
    } catch (_) {
      return response.body;
    }

    return response.body;
  }

  void dispose() {
    _client.close();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
