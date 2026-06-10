import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:trying_flutter/models/comment.dart';
import 'package:trying_flutter/providers/comment_provider.dart';
import 'package:trying_flutter/services/error_helper.dart';
import 'package:trying_flutter/theme/app_colors.dart';
import 'package:trying_flutter/theme/app_typography.dart';

class ErrorDescriptionScreen extends ConsumerWidget {
  const ErrorDescriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final String errorcommentId = dotenv.get('ISSUE_ERROR_ID');

    final errorcommentComments = ref.watch(commentsProvider(errorcommentId));

    return errorcommentComments.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка комментариев...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(getErrorIcon(error), color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                getErrorMessage(error),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (canRetryError(error))
                ElevatedButton(
                  onPressed: () => ref.invalidate(commentsProvider),
                  child: const Text('Повторить'),
                ),
            ],
          ),
        ),
        data: (comments) {
          if (comments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: AppColors.greyMedium),
                  const SizedBox(height: 16),
                  Text(
                    'Нет комментов',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: AppColors.greyMedium,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildcommentCard(context, comment);
            },
          );
        },
      );
  }

  Widget _buildcommentCard(BuildContext context, Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment.id.toString(),
                style: AppTypography.issueId,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: comment.text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.issueDescription,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.greyMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            comment.createdBy,
                            style: AppTypography.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.greyMedium),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(comment.createdAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}