import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:trying_flutter/models/comment.dart';
import 'package:trying_flutter/models/issue.dart';
import 'package:trying_flutter/models/status.dart';
import 'package:trying_flutter/models/user.dart';

import '../services/api_exceptions.dart';
import '../services/log_utils.dart';
import '../services/yandex_auth.dart';

class NewApiClient {
  late final Dio _dio;
  final String baseUrl = 'https://api.tracker.yandex.net/v3';
  final String _orgId = dotenv.get('ORG_ID');
  final Logger _logger = Logger();
  final bool _debugMode = dotenv.getBool('DEBUG_MODE', fallback: false);

  NewApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        headers: {
          'Host': 'api.tracker.yandex.net',
        },
      ),
    );

    // Добавляем единый interceptor для обработки всех запросов
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Добавляем авторизацию и организацию
          options.headers['Authorization'] =
              'OAuth ${YandexAuthService.accessToken}';
          options.headers['X-Cloud-Org-Id'] = _orgId;

          // Сохраняем время начала запроса
          options.extra['_startTime'] = DateTime.now();

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (!_debugMode) {
            return handler.next(response);
          }

          final startTime =
              response.requestOptions.extra['_startTime'] as DateTime?;
          final elapsed = startTime != null
              ? DateTime.now().difference(startTime)
              : null;

          final sb = StringBuffer();
          sb.writeln(
            formatRequestLine(
              response.requestOptions.method,
              response.requestOptions.path,
            ),
          );
          sb.writeln();
          sb.writeln(formatHeaders(response.requestOptions.headers));
          sb.writeln(formatBody(response.requestOptions.data));
          sb.writeln();
          sb.writeln(separator);
          sb.writeln();
          sb.writeln(formatReceivedAt(DateTime.now()));
          if (elapsed != null) {
            sb.writeln(formatTimeDuration(elapsed));
          }
          sb.writeln(formatStatusLine(response.statusCode ?? 0));
          sb.writeln();
          sb.writeln(formatResponseBody(response.data));

          _logger.i(sb.toString());

          return handler.next(response);
        },
        onError: (error, handler) {
          if (!_debugMode) {
            throw _handleDioException(error);
          }

          final startTime =
              error.requestOptions.extra['_startTime'] as DateTime?;
          final elapsed = startTime != null
              ? DateTime.now().difference(startTime)
              : null;

          final sb = StringBuffer();
          sb.writeln(
            formatRequestLine(
              error.requestOptions.method,
              error.requestOptions.path,
            ),
          );
          sb.writeln();
          sb.writeln(formatHeaders(error.requestOptions.headers));
          sb.writeln(formatBody(error.requestOptions.data));
          sb.writeln();
          sb.writeln(separator);
          sb.writeln();
          sb.writeln(formatReceivedAt(DateTime.now()));
          if (elapsed != null) {
            sb.writeln(formatTimeDuration(elapsed));
          }

          if (error.response != null) {
            sb.writeln(formatStatusLine(error.response!.statusCode ?? 0));
            sb.writeln();
            sb.writeln(formatResponseBody(error.response!.data));
          } else {
            sb.writeln(formatErrorMessage(error.message ?? 'Unknown error'));
          }

          _logger.e(sb.toString());

          // Конвертируем DioException в наши кастомные исключения и выбрасываем
          throw _handleDioException(error);
        },
      ),
    );
  }

  /// Конвертирует DioException в ApiException или NetworkException
  Exception _handleDioException(DioException error) {
    final path = error.requestOptions.path;

    // Обработка таймаутов и сетевых ошибок
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        'Таймаут при $path',
        originalException: error,
      );
    }

    if (error.type == DioExceptionType.unknown) {
      // Проверяем, это ошибка сокета или интернета
      if (error.error is SocketException) {
        return NetworkException(
          'Нет соединения при $path',
          originalException: error,
        );
      }
      return NetworkException(
        'Неизвестная ошибка при $path',
        originalException: error,
      );
    }

    // Если есть ответ от сервера, используем его
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? -1;
      final errorMessage = _extractErrorMessage(error.response!);

      return ApiException(
        statusCode: statusCode,
        message:
            'Ошибка при $path: ${error.response!.statusMessage ?? 'неверный ответ'}',
        url: error.requestOptions.path,
        details: errorMessage,
      );
    }

    // Остальные ошибки
    return ApiException(
      statusCode: -1,
      message: 'Непредвиденная ошибка при $path: ${error.message}',
      url: path,
      details: error.toString(),
    );
  }

  /// Извлекает сообщение об ошибке из тела ответа
  String _extractErrorMessage(Response response) {
    if (response.data == null) {
      return 'Пустое тело ответа';
    }

    try {
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        return map['message']?.toString() ??
            map['error']?.toString() ??
            response.data.toString();
      }
      return response.data.toString();
    } catch (_) {
      return response.data.toString();
    }
  }

  /// Универсальная функция для выполнения запросов с обработкой ошибок
  Future<T> _executeRequest<T>(
    Future<T> Function() requestFn,
    String action,
  ) async {
    try {
      return await requestFn();
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      _logger.e('Unexpected error in $action: $e\n$st');
      throw ApiException(
        statusCode: -1,
        message: 'Непредвиденная ошибка при $action',
        url: baseUrl,
        details: e.toString(),
      );
    }
  }

  static const Map<String, List<String>> _transitionRequiredFields = {
    'testing': [
      'qaEngineer',
    ],
    'needInfo': ['pendingReplyFrom'],
  };

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

  /// Запрос на получение пользователей
  Future<List<User>> fetchUsers() async {
    return _executeRequest(
      () async {
        final response = await _dio.get('/users');
        final list = response.data as List<dynamic>;
        return list
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      'получение пользователей',
    );
  }

  /// Запрос на получение конкретного пользователя
  Future<User> fetchCurrentUser() async {
    return _executeRequest(
      () async {
        final response = await _dio.get('/myself');
        return User.fromJson(response.data as Map<String, dynamic>);
      },
      'получение текущего пользователя',
    );
  }

  /// Запрос на переход в статус с полями
  Future<void> statusTransition(
    String issueId,
    String transitionId, {
    Map<String, dynamic> fieldValues = const {},
  }) async {
    final payload = _buildTransitionPayload(transitionId, fieldValues);

    await _executeRequest<Null>(
      () async {
        await _dio.post(
          '/issues/$issueId/transitions/$transitionId/_execute',
          data: payload,
        );
        return null;
      },
      'переход в статус',
    );
  }

  /// Метод для получения статусов, в которые задача может перейти
  Future<List<Status>> fetchStatuses(String issueId) async {
    return _executeRequest(
      () async {
        final response = await _dio.get('/issues/$issueId/transitions');
        final list = response.data as List<dynamic>;
        return list
            .map((item) => Status.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      'получение статусов',
    );
  }

  /// Метод для добавления комментария к задаче
  Future<Comment> addingComment(String issueId, String commentText) async {
    return _executeRequest(
      () async {
        final response = await _dio.post(
          '/issues/$issueId/comments',
          data: {'text': commentText},
        );
        return Comment.fromJson(response.data as Map<String, dynamic>);
      },
      'добавление комментария',
    );
  }

  /// Метод для добавления комментария с описанием ошибки к задаче
  Future<Comment> addingErrorComment(String commentText) async {
    final String errorIssueId = dotenv.get('ISSUE_ERROR_ID');
    return _executeRequest(
      () async {
        final response = await _dio.post(
          '/issues/$errorIssueId/comments',
          data: {'text': commentText},
        );
        return Comment.fromJson(response.data as Map<String, dynamic>);
      },
      'добавление описания ошибки',
    );
  }


  /// Получение ID аватарки пользователя из Яндекс профиля
  Future<String?> fetchUserAvatarId() async {
    return _executeRequest(
      () async {
        final response = await _dio.get(
          'https://login.yandex.ru/info?format=json',
          options: Options(
            headers: {
              'Authorization': 'OAuth ${YandexAuthService.accessToken}',
            },
          ),
        );
        final map = response.data as Map<String, dynamic>;
        final isEmpty = map['is_avatar_empty'] as bool? ?? false;
        final avatarId = map['default_avatar_id'] as String?;
        if (isEmpty || avatarId == null || avatarId.isEmpty) return null;
        return avatarId;
      },
      'получение ID аватарки',
    );
  }

  /// Запрос на получение списка задач по статусу "Можно тестировать"
  Future<List<Issue>> showIssues() async {
    return _executeRequest(
      () async {
        final response = await _dio.post(
          '/issues/_search?',
          data: {
            'query': "Resolution: empty() \"Status Type\": !cancelled \"Status Type\": !done Status: readyForTest, testing \"Sort by\": Updated DESC",
            'order': '+status',
          },
        );
        final list = response.data as List<dynamic>;
        return list
            .map((item) => Issue.fromJson(item as Map<String, dynamic>))
            .toList();
      },
      'получение задач',
    );
  }

  Future<Issue> fetchIssue(String issueId) async {
    return _executeRequest(
      () async {
        final response = await _dio.get('/issues/$issueId');
        return Issue.fromJson(response.data as Map<String, dynamic>);
      },
      'получение задачи',
    );
  }

  Future<List<Comment>> fetchComments(String issueId) {
    return _executeRequest(
      () async {
        final response = await _dio.get('/issues/$issueId/comments');
        final list = response.data as List<dynamic>;
        return list
              .map((item) => Comment.fromJson(item as Map<String, dynamic>))
              .toList();
      },
      'получение комментариев');
  }

  void dispose() {
    _dio.close();
  }
}

final newApiClientProvider = Provider<NewApiClient>((ref) {
  return NewApiClient();
});