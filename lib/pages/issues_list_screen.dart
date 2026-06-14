import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/models/issue.dart';
import 'package:trying_flutter/providers/issue_provider.dart';
import 'package:trying_flutter/providers/issues_preloader_provider.dart';
import 'package:trying_flutter/services/error_helper.dart';
import 'package:trying_flutter/theme/app_colors.dart';
import 'package:trying_flutter/theme/app_typography.dart';

class IssuesListScreen extends ConsumerWidget {
  const IssuesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final issuesAsync = ref.watch(issuesProvider);
    final preloaderStatusAsync = ref.watch(issuesPreloaderProvider);

    return issuesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка задач...'),
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
                  onPressed: () => ref.invalidate(issuesProvider),
                  child: const Text('Повторить'),
                ),
            ],
          ),
        ),
        data: (issues) {
          // Запускаем предзагрузку когда задачи загружены
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(issuesPreloaderProvider.notifier).startPreloading(issues);
          });

          if (issues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: AppColors.greyMedium),
                  const SizedBox(height: 16),
                  Text(
                    'Нет задач на тестировании',
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

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final issue = issues[index];
                  return _buildIssueCard(context, issue);
                },
              ),
              // Показываем прогресс загрузки если активна предзагрузка
              preloaderStatusAsync.when(
                data: (status) {
                  if (!status.isActive || status.phase == PreloadingPhase.idle) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getPhaseText(status.phase),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${status.completedIssues}/${status.totalIssues}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: status.progress,
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.brandBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      );
  }

  Widget _buildIssueCard(BuildContext context, Issue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/issue/${issue.id}'),
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
                    child: Text(
                      issue.key,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  _buildStatusChip(issue.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                issue.summary ?? 'Без названия',
                style: AppTypography.issueSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityChip(issue.priority),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.greyMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            issue.createdBy,
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
                        _formatDate(issue.createdAt),
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'открыт':
      case 'open':
        color = AppColors.statusOpen;
        break;
      case 'в работе':
      case 'in progress':
        color = AppColors.statusInProgress;
        break;
      case 'на тестировании':
      case 'testing':
      case 'готов к тестированию':
      case 'readyfortest':
      case 'ready for test':
      case 'можно тестировать':
        color = AppColors.statusTesting;
        break;
      case 'закрыт':
      case 'closed':
        color = AppColors.statusClosed;
        break;
      default:
        color = AppColors.statusClosed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: AppColors.greyDark,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'критический':
        color = AppColors.priorityCritical;
        break;
      case 'high':
      case 'высокий':
        color = AppColors.priorityHigh;
        break;
      case 'medium':
      case 'средний':
        color = AppColors.priorityMedium;
        break;
      case 'low':
      case 'низкий':
        color = AppColors.priorityLow;
        break;
      default:
        color = AppColors.greyMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getPhaseText(PreloadingPhase phase) {
    switch (phase) {
      case PreloadingPhase.loadingIssues:
        return 'Загрузка деталей задач...';
      case PreloadingPhase.loadingStatuses:
        return 'Загрузка статусов...';
      case PreloadingPhase.loadingComments:
        return 'Загрузка комментариев...';
      default:
        return 'Загрузка...';
    }
  }
}