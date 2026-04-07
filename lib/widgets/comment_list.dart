import 'package:flutter/material.dart';
import '../models/comment.dart';

class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final VoidCallback? onRefresh;

  const CommentList({
    super.key,
    required this.comments,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Комментарии:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onRefresh != null)
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Обновить'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: comments.isEmpty
              ? const Center(
                  child: Text(
                    'Комментариев пока нет',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentCard(comments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.createdBy,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(comment.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 14),
            ),
            // Если есть дата обновления и она отличается от даты создания
            if (comment.updatedAt != null && 
                comment.updatedAt != comment.createdAt) ...[
              const SizedBox(height: 4),
              Text(
                'Изменён: ${_formatDate(comment.updatedAt!)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}