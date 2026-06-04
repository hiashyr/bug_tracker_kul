import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/services/api_exceptions.dart';
import '../models/comment.dart';
import '../services/new_api_client.dart';
import 'auth_provider.dart';

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, issueId) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
      throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
    }

  final apiClient = ref.watch(newApiClientProvider);
  return apiClient.fetchComments(issueId);
});

final addCommentProvider = Provider((ref) {
  return (String issueId, String commentText) async {
  final isAuthorized = ref.watch(isAuthorizedProvider);
  if (!isAuthorized) {
    throw ApiException(statusCode: 401, message: 'Требуется авторизация', url: '');  
  }

    final apiClient = ref.read(newApiClientProvider);
    final newComment = await apiClient.addingComment(issueId, commentText);
    ref.invalidate(commentsProvider(issueId));
    return newComment;
  };
});