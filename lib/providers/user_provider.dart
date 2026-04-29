import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchUsers();
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authUser = ref.watch(authStateProvider);
  if (authUser == null) return null;

  final apiClient = ref.read(apiClientProvider);
  final avatarId = await apiClient.fetchUserAvatarId();

  return User(
    login: authUser.login,
    display: authUser.display,
    email: authUser.email,
    cloudUid: authUser.cloudUid,
    defaultAvatarId: avatarId,
    isAvatarEmpty: avatarId == null,
  );
});

final validUsersProvider = FutureProvider<List<User>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final users = await ref.watch(usersProvider.future);
  return users.where((u) => u.cloudUid != null && u.cloudUid!.isNotEmpty).toList();
});