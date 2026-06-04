import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/api_exceptions.dart';
import 'package:trying_flutter/services/new_api_client.dart';
import '../models/issue.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final issueProvider = FutureProvider.family<Issue, String>((ref, issueId) async {  
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
      throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
    }
  final apiClient = ref.watch(newApiClientProvider);  
  return apiClient.fetchIssue(issueId);  
});

final issuesProvider = FutureProvider<List<Issue>>((ref) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
      throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
    }
  final apiClient = ref.watch(newApiClientProvider);  
  return apiClient.showIssues();  
});  