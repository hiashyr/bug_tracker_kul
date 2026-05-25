import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final _reset = '\x1B[0m';
final _yellow = '\x1B[33m';
final _magenta = '\x1B[35m';
final _cyan = '\x1B[36m';

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Logger _logger = Logger();

  final bool _debugMode = dotenv.getBool('DEBUG_MODE', fallback: false);
  static const int _maxBodyLength = 2000;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? bodyString;
    if (request is http.Request) {
      bodyString = request.body;
    }
    
    final stopwatch = Stopwatch()..start();

    late final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e, stackTrace) {
      stopwatch.stop();
      if (_debugMode) {
        _logger.e(
          'HTTP request failed: ${request.method} ${request.url}\n$e\n$stackTrace',
        );
      }
      rethrow;
    }

    stopwatch.stop();
    final receivedAt = DateTime.now().toUtc();
    final responseBody = await response.stream.bytesToString();

    if (_debugMode) {
      final requestBodyLog = bodyString != null && bodyString.isNotEmpty
          ? '${_magenta}BODY:$_reset ${_truncateAndPrettyPrint(bodyString)}'
          : '';

      final responseBodyLog = responseBody.isNotEmpty
          ? '${_magenta}BODY_OF_RESPONSE:$_reset ${_truncateAndPrettyPrint(responseBody)}'
          : '';

      _logger.i('''
${request.method} $_yellow${request.url}$_reset

${_magenta}HEADERS:$_reset ${request.headers}
${requestBodyLog.isNotEmpty ? '\n$requestBodyLog' : ''}

$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset

${_magenta}RECEIVED AT  :$_reset ${receivedAt.toIso8601String()}
${_magenta}TIME DURATION:$_reset ${_formatDuration(stopwatch.elapsed)}

${_magenta}STATUS_OF_RESPONSE:$_reset ${response.statusCode}

${responseBodyLog.isNotEmpty ? '\n$responseBodyLog' : ''}
''');
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  String _truncateAndPrettyPrint(String jsonString) {
    final prettyString = _prettyPrintJson(jsonString);

    if (prettyString.length > _maxBodyLength) {
      final truncated = prettyString.substring(0, _maxBodyLength);
      final totalSize = jsonString.length;
      return '$truncated\n... [truncated, total size: ${_formatSize(totalSize)}]';
    }

    return prettyString;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _prettyPrintJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return jsonString;
    }
  }

  String _formatDuration(Duration duration) {
    final ms = duration.inMicroseconds / 1000.0;
    return '${ms.toStringAsFixed(6)}ms';
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}