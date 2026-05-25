import 'package:flutter/material.dart';

import 'api_exceptions.dart';

String getErrorMessage(Object error) {
  if (error is ApiException) {
    return error.userMessage;
  }

  if (error is NetworkException) {
    return 'Проблема с сетью. Проверьте подключение и попробуйте снова.';
  }

  if (error is JsonParsingException) {
    return 'Ошибка обработки данных. Попробуйте обновить страницу позже.';
  }

  return 'Произошла ошибка. Попробуйте ещё раз.';
}

IconData getErrorIcon(Object error) {
  if (error is ApiException) {
    switch (error.errorType) {
      case ApiErrorType.notFound:
        return Icons.search_off;
      case ApiErrorType.unauthorized:
        return Icons.lock;
      case ApiErrorType.forbidden:
        return Icons.block;
      case ApiErrorType.conflict:
        return Icons.error_outline;
      case ApiErrorType.badRequest:
        return Icons.warning_amber_rounded;
      case ApiErrorType.serverError:
        return Icons.cloud_off;
      case ApiErrorType.unknown:
        return Icons.error_outline;
    }
  }

  if (error is NetworkException) {
    return Icons.wifi_off;
  }

  if (error is JsonParsingException) {
    return Icons.memory;
  }

  return Icons.error_outline;
}

bool canRetryError(Object error) {
  if (error is ApiException) {
    return error.isRetryable;  // Просто используем его
  }
  if (error is NetworkException) {
    return true;
  }
  return false;
}