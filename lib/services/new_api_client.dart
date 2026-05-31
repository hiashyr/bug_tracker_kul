import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:trying_flutter/models/user.dart';

import '../services/api_exceptions.dart';
import '../services/yandex_auth.dart';

class NewApiClient {
  late final Dio _dio;
  final String baseUrl = 'https://api.tracker.yandex.net/v3';
  final String _orgId = dotenv.get('ORG_ID');
  final Logger _logger = Logger();

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

          _logger.d(
            '🔵 Request: ${options.method} ${options.path}\n'
            '   Headers: ${options.headers}',
          );

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            '🟢 Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          // Логируем ошибку
          _logger.e(
            '🔴 Error: ${error.response?.statusCode} ${error.requestOptions.path}\n'
            '   Message: ${error.message}',
          );

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

  void dispose() {
    _dio.close();
  }
}

final newApiClientProvider = Provider<NewApiClient>((ref) {
  return NewApiClient();
});
