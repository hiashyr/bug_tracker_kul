import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/models/issue.dart';
import 'package:trying_flutter/providers/issue_provider.dart';
import 'package:trying_flutter/providers/issues_preloader_provider.dart';
import 'package:trying_flutter/services/error_helper.dart';
import 'package:trying_flutter/theme/app_colors.dart';
import 'package:trying_flutter/theme/app_typography.dart';

class IssuesListScreen extends ConsumerStatefulWidget {
  const IssuesListScreen({super.key});

  @override
  ConsumerState<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends ConsumerState<IssuesListScreen> {

  bool _preloadingStarted = false;

  int _currentPage = 0;
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Все',
    'Тестируется',
    'Можно тестировать',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Issue> _filterIssues(List<Issue> issues) {
    var filtered = issues;

    // Фильтр по поиску в названии
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((issue) {
        final summary = issue.summary ?? '';
        return summary.toLowerCase().contains(query);
      }).toList();
    }

    // Фильтр по статусу
    if (_selectedStatus != null && _selectedStatus != 'Все') {
      filtered = filtered.where((issue) {
        return issue.status.toLowerCase() == _selectedStatus!.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 0;
    });
  }

  void _onStatusChanged(String? value) {
    setState(() {
      _selectedStatus = value;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {
                    _currentPage = 0;
                    ref.invalidate(issuesProvider);
                  },
                  child: const Text('Повторить'),
                ),
            ],
          ),
        ),
        data: (issues) {
          // Запускаем предзагрузку когда задачи загружены
          if (!_preloadingStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _preloadingStarted = true;
              ref.read(issuesPreloaderProvider.notifier).startPreloading(issues);
            });
          }

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

          // Применяем фильтры к задачам
          final filteredIssues = _filterIssues(issues);

          if (filteredIssues.isEmpty) {
            return Center(
              child: Column(
                children: [
                  _buildSearchAndFilterBar(),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Нет задач, соответствующих фильтрам',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.greyMedium,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final totalPages = (filteredIssues.length / _pageSize).ceil();
          if (_currentPage >= totalPages) _currentPage = 0;
          final start = _currentPage * _pageSize;
          final end = (start + _pageSize > filteredIssues.length)
              ? filteredIssues.length
              : start + _pageSize;
          final pageIssues = filteredIssues.sublist(start, end);

          return Column(
            children: [
              _buildSearchAndFilterBar(),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      itemCount: pageIssues.length,
                      itemBuilder: (context, index) {
                        final issue = pageIssues[index];
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
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
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

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.greyLight.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Поиск по названию...',
              hintStyle: AppTypography.caption,
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.greyMedium),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.greyMedium),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusOptions.map((status) {
                  final isSelected = (status == 'Все' && _selectedStatus == null) ||
                      status == _selectedStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _onStatusChanged(status == 'Все' ? null : status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.brandBlue : AppColors.greyMedium,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.textOnBrand : AppColors.greyDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
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
                        const Icon(Icons.person_outline, size: 14, color: AppColors.brandBlue),
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
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.brandBlue),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(issue.createdAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (issue.qaEngineer != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bug_report_outlined, size: 14, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Тестировщик: ${issue.qaEngineer}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: AppColors.priorityHigh,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
      case 'критичный':
        color = AppColors.priorityCritical;
        break;
      case 'блокер':
        color = AppColors.priorityBlocker;
        break;
      case 'средний':
        color = AppColors.priorityMedium;
        break;
      case 'low':
      case 'низкий':
        color = AppColors.greyDark;
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