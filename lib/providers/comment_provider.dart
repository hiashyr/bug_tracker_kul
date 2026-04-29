import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, issueId) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchComments(issueId);
});

final addCommentProvider = Provider((ref) {
  return (String issueId, String commentText) async {
    final user = ref.read(authStateProvider);
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    final apiClient = ref.read(apiClientProvider);
    final newComment = await apiClient.addingComment(issueId, commentText);
    ref.invalidate(commentsProvider(issueId));
    return newComment;
  };
});