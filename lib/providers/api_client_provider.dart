import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/api_client.dart';
import 'auth_provider.dart';

final apiClientAsyncProvider = FutureProvider<ApiClient>((ref) async {
  final token = await ref.watch(iamTokenHeaderProvider.future);
  return ApiClient(authorizationHeader: token);
});