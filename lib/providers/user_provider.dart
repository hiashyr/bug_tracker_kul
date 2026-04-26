import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchUsers();
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  return user;
});

final validUsersProvider = FutureProvider<List<User>>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return [];

  final users = await ref.watch(usersProvider.future);
  return users
      .where((u) => u.cloudUid != null && u.cloudUid!.isNotEmpty)
      .toList();
});