import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/api_exceptions.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final usersProvider = FutureProvider<List<User>>((ref) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
      throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
    }
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchUsers();
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
    throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');
  }

  final apiClient = ref.read(apiClientProvider);
  final defaultAvatarId = await apiClient.fetchUserAvatarId();
  final apiUser = await apiClient.fetchCurrentUser();

  return User(
    login: apiUser.login,
    display: apiUser.display,
    email: apiUser.email,
    cloudUid: apiUser.cloudUid,
    defaultAvatarId: defaultAvatarId,
    isAvatarEmpty: defaultAvatarId == null || defaultAvatarId.isEmpty,
  );
});

final validUsersProvider = FutureProvider<List<User>>((ref) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
      throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
    }
  final users = await ref.watch(usersProvider.future);
  return users.where((u) => u.cloudUid != null && u.cloudUid!.isNotEmpty).toList();
});