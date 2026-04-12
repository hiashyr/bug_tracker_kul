import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/issue_provider.dart';
import '../models/status.dart';
import '../services/api_client.dart';

final statusesProvider = FutureProvider.family<List<Status>, String>((
  ref,
  issueId,
) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchStatuses(issueId);
});

final statusTransitionProvider = Provider((ref) {
  return (
    String issueId,
    String transitionId, {
    Map<String, dynamic> fieldValues = const {},
  }) async {
    final apiClient = ref.read(apiClientProvider);

    // Выполняем переход со значениями полей
    await apiClient.statusTransition(
      issueId,
      transitionId,
      fieldValues: fieldValues,
    );

    // Обновляем данные задачи (статус изменился)
    ref.invalidate(issueProvider(issueId));

    // Обновляем список доступных статусов (они могли измениться)
    ref.invalidate(statusesProvider(issueId));
  };
});
