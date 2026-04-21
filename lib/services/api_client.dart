import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trying_flutter/models/user.dart';

import '../models/comment.dart';
import '../models/issue.dart';
import '../models/status.dart';
import '../services/api_exceptions.dart';
import '../services/logging.dart';

class ApiClient {
  final String baseUrl = 'https://api.tracker.yandex.net/v3';
  final String _orgId = dotenv.get('ORG_ID');
  final String _token = dotenv.get('TOKEN');
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? LoggingClient();

  static const Duration _requestTimeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
    'Authorization': 'OAuth $_token',
    'Content-Type': 'application/json',
    'Host': 'api.tracker.yandex.net',
    'X-Cloud-Org-Id': _orgId,
  };

  static const Map<String, List<String>> _transitionRequiredFields = {
    // Пример, если бы у некоторых переходов были обязательные поля
    // 'transition_to_review': ['reviewerComment', 'reviewReason'],
    // 'transition_done': ['closedReason'],
    'testing': ['qaEngineer'], // Это поле принимает username из запроса. Сущность User
    'needInfo': ['pendingReplyFrom'] // Также принимает username из запроса.
  };

  // Запрос на получение пользователей
  Future<List<User>> fetchUsers() async {
    final response = await _sendRequest(
      () => _client.get(Uri.parse('$baseUrl/users'), headers: _headers),
      action: 'получение пользователей',
    );

    _validateStatus(response, 200, action: 'fetchUsers');
    return _decodeJson(response.body, (json) {
      final list = json as List<dynamic>;
      return list
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    }, action: 'fetchUsers');
  }

  // Запрос на получение конкретного пользователя
  Future<User> fetchCurrentUser() async {
    final response = await _sendRequest(
      () => _client.get(Uri.parse('$baseUrl/myself'), headers: _headers),
      action: 'получение текущего пользователя',
    );

    _validateStatus(response, 200, action: 'fetchUsers');
    return _decodeJson(
      response.body,
      (json) => User.fromJson(json as Map<String, dynamic>),
      action: 'получение конкретного пользователя',
    );
  }
  
    // Запрос на переход в статус с полями. Поля берем из _transitionRequiredFields
    Future<void> statusTransition(
      String issueId,
      String transitionId, {
      Map<String, dynamic> fieldValues = const {},
    }) async {
      final payload = _buildTransitionPayload(transitionId, fieldValues);

      final response = await _sendRequest(
        () => _client.post(
          Uri.parse(
            '$baseUrl/issues/$issueId/transitions/$transitionId/_execute',
          ),
          headers: _headers,
          body: jsonEncode(payload),
        ),
        action: 'переход в статус',
      );

      _validateStatus(response, 200, action: 'statusTransition');
      // Нам не нужно парсить Status, так как статус уже изменился
      return;
    }

  Map<String, dynamic> _buildTransitionPayload(
    String transitionId, [
    Map<String, dynamic> fieldValues = const {},
  ]) {
    final requiredFields = _transitionRequiredFields[transitionId];
    if (requiredFields == null || requiredFields.isEmpty) {
      return {};
    }

    return {
      for (final field in requiredFields) field: fieldValues[field],
    };
  }
  
  // Метод для получения одной задачи по ID
  Future<Issue> fetchIssue(String issueId) async {
    final response = await _sendRequest(
      () =>
          _client.get(Uri.parse('$baseUrl/issues/$issueId'), headers: _headers),
      action: 'получение задачи',
    );

    _validateStatus(response, 200, action: 'fetchIssue');
    return _decodeJson(
      response.body,
      (json) => Issue.fromJson(json as Map<String, dynamic>),
      action: 'получение задачи',
    );
  }

  // Метод для получения статусов, в которые задача может перейти
  Future<List<Status>> fetchStatuses(String issueId) async {
    final response = await _sendRequest(
      () => _client.get(
        Uri.parse('$baseUrl/issues/$issueId/transitions'),
        headers: _headers,
      ),
      action: 'получение статусов',
    );

    _validateStatus(response, 200, action: 'fetchStatuses');
    return _decodeJson(response.body, (json) {
      final list = json as List<dynamic>;
      return list
          .map((item) => Status.fromJson(item as Map<String, dynamic>))
          .toList();
    }, action: 'fetchStatuses');
  }

  // Методя для получения комментариев задачи
  Future<List<Comment>> fetchComments(String issueId) async {
    final response = await _sendRequest(
      () => _client.get(
        Uri.parse('$baseUrl/issues/$issueId/comments'),
        headers: _headers,
      ),
      action: 'получение комментариев',
    );

    _validateStatus(response, 200, action: 'fetchComments');
    return _decodeJson(response.body, (json) {
      final list = json as List<dynamic>;
      return list
          .map((item) => Comment.fromJson(item as Map<String, dynamic>))
          .toList();
    }, action: 'fetchComments');
  }

  // Метод для добавления комментария к задаче
  Future<Comment> addingComment(String issueId, String commentText) async {
    final response = await _sendRequest(
      () => _client.post(
        Uri.parse('$baseUrl/issues/$issueId/comments'),
        headers: _headers,
        body: jsonEncode({'text': commentText}),
      ),
      action: 'добавление комментария',
    );

    _validateStatus(response, 201, action: 'addingComment');
    return _decodeJson(
      response.body,
      (json) => Comment.fromJson(json as Map<String, dynamic>),
      action: 'addingComment',
    );
  }

  // Метод для получения списка задач по статусу "Можно тестировать"
  Future<List<Issue>> showIssues() async {
    final response = await _sendRequest(
      () => _client.post(
        Uri.parse('$baseUrl/issues/_search?expand=transitions'),
        headers: _headers,
        body: jsonEncode({
          'filter': {'queue': 'DEV', 'status': 'readyForTest'},
          'order': '+status',
        }),
      ),
      action: 'получение списка задач',
    );

    _validateStatus(response, 200, action: 'showIssues');
    return _decodeJson(response.body, (json) {
      final list = json as List<dynamic>;
      return list
          .map((item) => Issue.fromJson(item as Map<String, dynamic>))
          .toList();
    }, action: 'showIssues');
  }

  // Универсальный метод для отправки HTTP-запросов с обработкой ошибок и логированием
  Future<http.Response> _sendRequest(
    Future<http.Response> Function() requestFn, {
    required String action,
  }) async {
    try {
      return await requestFn().timeout(_requestTimeout);
    } on SocketException catch (e) {
      throw NetworkException(
        'Нет соединения с сетью при $action',
        originalException: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        'Таймаут запроса при $action',
        originalException: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Ошибка HTTP клиента при $action: ${e.message}',
        originalException: e,
      );
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Непредвиденная ошибка при $action: $e',
        url: baseUrl,
        details: e.toString(),
      );
    }
  }

  // Валидация статуса ответа
  void _validateStatus(
    http.Response response,
    int expectedStatus, {
    required String action,
  }) {
    if (response.statusCode != expectedStatus) {
      final errorMessage = _extractErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message:
            'Ошибка сервера при $action: ${response.reasonPhrase ?? 'неверный ответ'}',
        url: response.request?.url.toString() ?? baseUrl,
        details: errorMessage,
      );
    }
  }

  // Универсальный метод для декодирования JSON с обработкой ошибок
  T _decodeJson<T>(
    String body,
    T Function(dynamic json) parser, {
    required String action,
  }) {
    try {
      final decoded = jsonDecode(body);
      return parser(decoded);
    } on FormatException catch (_) {
      throw JsonParsingException('Ошибка разбора JSON при $action', body);
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
