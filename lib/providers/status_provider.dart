import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/status.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';
import 'issue_provider.dart';

final statusesProvider = FutureProvider.family<List<Status>, String>((ref, issueId) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchStatuses(issueId);
});

final statusTransitionProvider = Provider((ref) {
  return (
    String issueId,
    String transitionId, {
    Map<String, dynamic> fieldValues = const {},
  }) async {
    final user = await ref.read(authStateProvider.future);
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final apiClient = ref.read(apiClientProvider);

    await apiClient.statusTransition(
      issueId,
      transitionId,
      fieldValues: fieldValues,
    );

    ref.invalidate(issueProvider(issueId));
    ref.invalidate(statusesProvider(issueId));
  };
});