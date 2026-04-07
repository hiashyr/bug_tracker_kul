import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../services/api_client.dart';


// Провайдер для получения комментариев по задаче
final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, issueId) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.fetchComments(issueId);
});


// Провайдер для добавления комментария
final addCommentProvider = Provider((ref) {
  return (String issueId, String commentText) async {
    
    final apiClient = ref.read(apiClientProvider);
    final newComment = await apiClient.addingComment(issueId, commentText);
    ref.invalidate(commentsProvider(issueId));
    
    return newComment;
  };
});