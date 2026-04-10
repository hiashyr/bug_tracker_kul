import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/issue_provider.dart';
import '../models/status.dart';
import '../services/api_client.dart';

final statusesProvider = FutureProvider.family<List<Status>, String>((ref, issueId) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchStatuses(issueId);
});

final statusTransitionProvider = Provider((ref) {
  return (String issueId, String transitionId) async {
    final apiClient = ref.read(apiClientProvider);
    
    // Выполняем переход
    await apiClient.statusTransition(issueId, transitionId);
    
    // Обновляем данные задачи (статус изменился)
    ref.invalidate(issueProvider(issueId));
    
    // Обновляем список доступных статусов (они могли измениться)
    ref.invalidate(statusesProvider(issueId));
  };
});