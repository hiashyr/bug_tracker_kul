import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/status.dart';
import '../services/api_client.dart';

final statusesProvider = FutureProvider.family<List<Status>, String>((ref, issueId) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchStatuses(issueId);
});