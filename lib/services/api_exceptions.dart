enum ApiErrorType {
  notFound,
  unauthorized,
  forbidden,
  conflict,
  badRequest,
  serverError,
  unknown,
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String url;
  final String? details;
  late final ApiErrorType errorType;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    this.details,
  }) {
    errorType = _categorizeError(statusCode);
  }

  static ApiErrorType _categorizeError(int statusCode) {
    if (statusCode == 404) return ApiErrorType.notFound;
    if (statusCode == 401) return ApiErrorType.unauthorized;
    if (statusCode == 403) return ApiErrorType.forbidden;
    if (statusCode == 409) return ApiErrorType.conflict;
    if (statusCode == 400) return ApiErrorType.badRequest;
    if (statusCode >= 500 && statusCode <= 599) return ApiErrorType.serverError;
    return ApiErrorType.unknown;
  }

  String get userMessage {
    switch (errorType) {
      case ApiErrorType.notFound:
        return 'Ресурс не найден. Возможно, он был удалён.';
      case ApiErrorType.unauthorized:
        return 'Требуется авторизация. Пожалуйста, переавторизуйтесь.';
      case ApiErrorType.forbidden:
        return 'У вас нет прав доступа к этому ресурсу.';
      case ApiErrorType.conflict:
        return 'Конфликт данных. Попробуйте обновить информацию.';
      case ApiErrorType.badRequest:
        return 'Неверный запрос. Проверьте данные и попробуйте снова.';
      case ApiErrorType.serverError:
        return 'Ошибка сервера. Попробуйте позже.';
      case ApiErrorType.unknown:
        return 'Неизвестная ошибка. Попробуйте позже.';
    }
  }

  bool get isRetryable {
    return errorType == ApiErrorType.serverError ||
        statusCode == 408 ||
        statusCode == 429;
  }

  @override
  String toString() {
    final detailsText = details != null ? '\nDetails: $details' : '';
    return 'ApiException($statusCode - ${errorType.name}) $message$detailsText\nURL: $url';
  }
}

class NetworkException implements Exception {
  final String message;
  final Object? originalException;

  NetworkException(this.message, {this.originalException});

  @override
  String toString() => 'NetworkException: $message';
}

class JsonParsingException implements Exception {
  final String message;
  final String body;

  JsonParsingException(this.message, this.body);

  @override
  String toString() => 'JsonParsingException: $message\nBody: $body';
}
