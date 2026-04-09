class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String url;
  final String? details;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    this.details,
  });

  @override
  String toString() {
    final detailsText = details != null ? '\nDetails: $details' : '';
    return 'ApiException($statusCode) $message$detailsText\nURL: $url';
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
