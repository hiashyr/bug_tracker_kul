import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/yandex_auth.dart';

final usersProvider = FutureProvider<List<User>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchUsers();
});

final currentUserProvider = FutureProvider<User>((ref) {
  if (YandexAuthService.user != null) {
    return Future.value(YandexAuthService.user!);
  }
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchCurrentUser();
});

// Провайдер-фильтр для отшивания ботов по полю cloudUid
final validUsersProvider = FutureProvider<List<User>>((ref) {
  final usersAsync = ref.watch(usersProvider);
  return usersAsync.when(
    data: (users) => users
        .where((u) => u.cloudUid != null && u.cloudUid!.isNotEmpty)
        .toList(),
    loading: () => [],
    error: (err, stack) => throw err,
  );
});