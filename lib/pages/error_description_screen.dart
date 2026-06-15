import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:trying_flutter/models/comment.dart';
import 'package:trying_flutter/providers/comment_provider.dart';
import 'package:trying_flutter/services/error_helper.dart';
import 'package:trying_flutter/theme/app_colors.dart';
import 'package:trying_flutter/theme/app_typography.dart';

class ErrorDescriptionScreen extends ConsumerStatefulWidget {
  const ErrorDescriptionScreen({super.key});

  @override
  ConsumerState<ErrorDescriptionScreen> createState() => _ErrorDescriptionScreenState();
}

class _ErrorDescriptionScreenState extends ConsumerState<ErrorDescriptionScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {

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
                  onPressed: () {
                    _currentPage = 0;
                    ref.invalidate(commentsProvider);
                  },
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

          final totalPages = (comments.length / _pageSize).ceil();
          if (_currentPage >= totalPages) _currentPage = 0;
          final start = _currentPage * _pageSize;
          final end = (start + _pageSize > comments.length)
              ? comments.length
              : start + _pageSize;
          final pageComments = comments.sublist(start, end);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pageComments.length,
                  itemBuilder: (context, index) {
                    final comment = pageComments[index];
                    return _buildcommentCard(context, comment);
                  },
                ),
              ),
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border(
                      top: BorderSide(color: AppColors.greyLight.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        color: AppColors.brandBlue,
                      ),
                      ...List.generate(totalPages, (i) {
                        final isActive = i == _currentPage;
                        return GestureDetector(
                          onTap: () => setState(() => _currentPage = i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.brandBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? AppColors.textOnBrand : AppColors.brandBlue,
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        color: AppColors.brandBlue,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
  }

  Widget _buildcommentCard(BuildContext context, Comment comment) {
    final id = comment.id.toString();
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Коммент №$id",
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: comment.text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.issueDescription.copyWith(color: AppColors.backgroundDark),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: .start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.brandBlue),
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
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.brandBlue),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(comment.createdAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (comment.updatedBy != null && comment.updatedBy != comment.createdBy) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 14, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Обновлён: ${comment.updatedBy}',
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(comment.updatedAt!),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.add(const Duration(hours: 3));
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$day.$month.${localDate.year} $hour:$minute';
  }
}