import 'dart:convert';

/// ANSI color codes for console output
final _reset = '\x1B[0m';
final _yellow = '\x1B[33m';
final _magenta = '\x1B[35m';
final _cyan = '\x1B[36m';
final _green = '\x1B[32m';
final _red = '\x1B[31m';

const _maxBodyLength = 500;

/// Formats a body (Map, List, or String) with JSON pretty-print and truncation.
String formatBody(dynamic body) {
  if (body == null) return '${_magenta}BODY:$_reset <no body>';
  try {
    final str = body is Map || body is List
        ? const JsonEncoder.withIndent('  ').convert(body)
        : body.toString();
    // Try pretty-print raw string JSON too
    final pretty = _prettyPrintJson(str);
    return '${_magenta}BODY:$_reset\n${_truncateWithSize(pretty)}';
  } catch (_) {
    return '${_magenta}BODY:$_reset\n${_truncateWithSize(body.toString())}';
  }
}

/// Formats response body with JSON pretty-print and truncation.
String formatResponseBody(dynamic data) {
  if (data == null) return '<no body>';
  try {
    final str = data is Map || data is List
        ? const JsonEncoder.withIndent('  ').convert(data)
        : data.toString();
    final pretty = _prettyPrintJson(str);
    return '${_magenta}BODY_OF_RESPONSE:$_reset\n${_truncateWithSize(pretty)}';
  } catch (_) {
    return '${_magenta}BODY_OF_RESPONSE:$_reset\n${_truncateWithSize(data.toString())}';
  }
}

/// Formats duration similar to logging.dart: microseconds with 6 decimal places.
String formatDuration(Duration duration) {
  final ms = duration.inMicroseconds / 1000.0;
  return '${ms.toStringAsFixed(6)}ms';
}

/// Formats headers map into a readable string.
String formatHeaders(Map<String, dynamic> headers) {
  final sanitized = Map<String, String>.fromEntries(
    headers.entries.map((e) {
      final key = e.key.toString();
      var value = e.value.toString();
      if (key.toLowerCase() == 'authorization') {
        value = 'OAuth ***';
      }
      return MapEntry(key, value);
    }),
  );
  return '${_magenta}HEADERS:$_reset $sanitized';
}

/// Formats a network-level error message (no response from server).
String formatErrorMessage(String message) {
  return '${_red}Error: $message$_reset';
}

/// Cyan separator line used between request and response sections.
String get separator =>
    '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset';

/// Formats the HTTP method and URL line with yellow color.
String formatRequestLine(String method, String url) {
  return '$_yellow$method $url$_reset';
}

/// Formats the status code line (green for 2xx, red for others).
String formatStatusLine(int statusCode) {
  final color = statusCode >= 200 && statusCode < 300 ? _green : _red;
  return '${_magenta}STATUS_OF_RESPONSE:$_reset $color$statusCode$_reset';
}

/// Formats the "Received at" timestamp line.
String formatReceivedAt(DateTime time) {
  return '${_magenta}RECEIVED AT:$_reset ${time.toUtc().toIso8601String()}';
}

/// Formats the "Time duration" line.
String formatTimeDuration(Duration duration) {
  return '${_magenta}TIME DURATION:$_reset ${formatDuration(duration)}';
}

// ---- Internal helpers ----

String _prettyPrintJson(String jsonString) {
  try {
    final decoded = jsonDecode(jsonString);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(decoded);
  } catch (_) {
    return jsonString;
  }
}

String _truncateWithSize(String text) {
  if (text.length <= _maxBodyLength) return text;
  final truncated = text.substring(0, _maxBodyLength);
  final totalSize = utf8.encode(text).length;
  return '$truncated\n... [truncated, total size: ${_formatSize(totalSize)}]';
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}