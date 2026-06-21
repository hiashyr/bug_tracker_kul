import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/comment.dart';
import '../theme/app_colors.dart';

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
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'Комментарии',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: comments.isEmpty
              ? const _EmptyCommentsState()
              : ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _CommentCard(comment: comments[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: AppColors.brandBlue.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Комментариев пока нет',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyMedium,
                ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment.createdBy,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.greyDark,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.greyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
              MarkdownBody(
                data: comment.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ),
            if (comment.updatedAt != null &&
                comment.updatedAt != comment.createdAt) ...[
              const SizedBox(height: 6),
              Text(
                'Изменён: ${_formatDate(comment.updatedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.greyMedium,
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}