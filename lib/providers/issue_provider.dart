import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/issue.dart';
import '../services/api_client.dart';

final issueProvider = FutureProvider.family<Issue, String>((ref, issueId) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchIssue(issueId);
});

final issuesProvider = FutureProvider<List<Issue>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.showIssues();
});