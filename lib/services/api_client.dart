import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trying_flutter/models/comment.dart';
import 'package:trying_flutter/models/status.dart';
import 'package:trying_flutter/services/logging.dart';
import '../models/issue.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  final String baseUrl = 'https://api.tracker.yandex.net/v3';
  final String _orgId = dotenv.get('ORG_ID');
  final String _token = dotenv.get('TOKEN');

  // Используем кастомный клиент вместо обычного
  final http.Client _client = LoggingClient();

  Map<String, String> get _headers => {
    'Authorization': 'OAuth $_token',
    'Content-Type': 'application/json',
    'Host': 'api.tracker.yandex.net',
    'X-Cloud-Org-Id': _orgId,
  };

  // Метод для получения одной задачи
  Future<Issue> fetchIssue(String issueId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/issues/$issueId'),
      headers: _headers
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return Issue.fromJson(jsonData);
    } else {
      throw Exception('Ошибка получения одной задачи: ${response.statusCode}');
    }
  }

  // Метод для получения статусов по задаче
  Future<List<Status>> fetchStatuses(String issueId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/issues/$issueId/transitions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Status.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки статусов: ${response.statusCode}');
    }
  }

  // Получение комментариев
  Future<List<Comment>> fetchComments(String issueId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/issues/$issueId/comments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки комментариев: ${response.statusCode}');
    }
  }

  // Добавление комментария
  Future<Comment> addingComment(String issueId, String commentText) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/issues/$issueId/comments'),
      headers: _headers,
      body: jsonEncode({"text": commentText}),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return Comment.fromJson(jsonData);
    } else {
      throw Exception('Ошибка добавления комментария: ${response.statusCode}');
    }
  }

  // Получение списка задач
  Future<List<Issue>> showIssues() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/issues/_search?expand=transitions'),
      headers: _headers,
      body: jsonEncode({
        "filter": {
          "queue": "DEV",
          "status": "readyForTest"
        },
        "order": "+status"
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Issue.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка получения списка задач: ${response.statusCode}');
    }
  }
  
  // Не забываем закрыть клиент при необходимости
  void dispose() {
    _client.close();
  }
}

// Провайдер для ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});