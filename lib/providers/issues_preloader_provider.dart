import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/issue_data_cache_provider.dart';
import '../models/issue.dart';
import '../services/new_api_client.dart';
import 'auth_provider.dart';

enum PreloadingPhase {
  idle,
  loadingIssues,
  loadingStatuses,
  loadingComments,
  completed,
}

class PreloadingStatus {
  final PreloadingPhase phase;
  final int totalIssues;
  final int completedIssues;
  final String? errorMessage;
  final bool isActive;

  PreloadingStatus({
    required this.phase,
    required this.totalIssues,
    required this.completedIssues,
    this.errorMessage,
    this.isActive = false,
  });

  double get progress {
    if (totalIssues == 0) return 0;
    if (phase == PreloadingPhase.loadingIssues) {
      return completedIssues / totalIssues * 0.33;
    } else if (phase == PreloadingPhase.loadingStatuses) {
      return 0.33 + (completedIssues / totalIssues * 0.34);
    } else if (phase == PreloadingPhase.loadingComments) {
      return 0.67 + (completedIssues / totalIssues * 0.33);
    } else if (phase == PreloadingPhase.completed) {
      return 1.0;
    }
    return 0;
  }

  PreloadingStatus copyWith({
    PreloadingPhase? phase,
    int? totalIssues,
    int? completedIssues,
    String? errorMessage,
    bool? isActive,
  }) {
    return PreloadingStatus(
      phase: phase ?? this.phase,
      totalIssues: totalIssues ?? this.totalIssues,
      completedIssues: completedIssues ?? this.completedIssues,
      errorMessage: errorMessage ?? this.errorMessage,
      isActive: isActive ?? this.isActive,
    );
  }
}

class IssuesPreloaderNotifier extends AsyncNotifier<PreloadingStatus> {
  @override
  Future<PreloadingStatus> build() async {
    return PreloadingStatus(
      phase: PreloadingPhase.idle,
      totalIssues: 0,
      completedIssues: 0,
      isActive: false,
    );
  }

  Future<void> startPreloading(List<Issue> issues) async {
    final isAuthorized = ref.watch(isAuthorizedProvider);
    if (!isAuthorized) {
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.idle,
          totalIssues: 0,
          completedIssues: 0,
          errorMessage: 'Требуется авторизация',
        ),
      );
      return;
    }

    if (issues.isEmpty) {
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.completed,
          totalIssues: 0,
          completedIssues: 0,
          isActive: true,
        ),
      );
      return;
    }

    try {
      final apiClient = ref.watch(newApiClientProvider);
      final cache = ref.read(issueDataCacheProvider.notifier);

      // Фаза 1: Загружаем детали задач параллельно
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.loadingIssues,
          totalIssues: issues.length,
          completedIssues: 0,
          isActive: true,
        ),
      );

      final issueDetailsFutures = <Future<void>>[];
      for (final issue in issues) {
        final future = _loadIssueDetails(apiClient, cache, issue.id);
        issueDetailsFutures.add(future);
      }
      await Future.wait(issueDetailsFutures);

      // Фаза 2: Загружаем статусы параллельно
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.loadingStatuses,
          totalIssues: issues.length,
          completedIssues: 0,
          isActive: true,
        ),
      );

      final statusesFutures = <Future<void>>[];
      for (final issue in issues) {
        final future = _loadStatuses(apiClient, cache, issue.id);
        statusesFutures.add(future);
      }
      await Future.wait(statusesFutures);

      // Фаза 3: Загружаем комментарии в фоне (не блокируем)
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.loadingComments,
          totalIssues: issues.length,
          completedIssues: 0,
          isActive: true,
        ),
      );

      final commentsFutures = <Future<void>>[];
      for (final issue in issues) {
        final future = _loadComments(apiClient, cache, issue.id);
        commentsFutures.add(future);
      }
      
      // Запускаем загрузку комментов в фоне, не ждем завершения
      Future.wait(commentsFutures).then((_) {
        state = AsyncValue.data(
          PreloadingStatus(
            phase: PreloadingPhase.completed,
            totalIssues: issues.length,
            completedIssues: issues.length,
            isActive: false,
          ),
        );
      }).catchError((error) {
        // Логируем ошибку, но не прерываем процесс
        print('Ошибка при загрузке комментов: $error');
      });

      // Обновляем состояние на "загружаю комментарии"
      state = AsyncValue.data(
        PreloadingStatus(
          phase: PreloadingPhase.loadingComments,
          totalIssues: issues.length,
          completedIssues: 0,
          isActive: true,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _loadIssueDetails(
    NewApiClient apiClient,
    IssueDataCacheNotifier cache,
    String issueId,
  ) async {
    try {
      final issue = await apiClient.fetchIssue(issueId);
      cache.setIssueData(issue);

      // Обновляем прогресс
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            completedIssues: currentState.completedIssues + 1,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке задачи $issueId: $e');
    }
  }

  Future<void> _loadStatuses(
    NewApiClient apiClient,
    IssueDataCacheNotifier cache,
    String issueId,
  ) async {
    try {
      final statuses = await apiClient.fetchStatuses(issueId);
      cache.setStatusesData(issueId, statuses);

      // Обновляем прогресс
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            completedIssues: currentState.completedIssues + 1,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке статусов для $issueId: $e');
    }
  }

  Future<void> _loadComments(
    NewApiClient apiClient,
    IssueDataCacheNotifier cache,
    String issueId,
  ) async {
    try {
      final comments = await apiClient.fetchComments(issueId);
      cache.setCommentsData(issueId, comments);

      // Обновляем прогресс
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            completedIssues: currentState.completedIssues + 1,
          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке комментов для $issueId: $e');
    }
  }

  void stop() {
    state = AsyncValue.data(
      PreloadingStatus(
        phase: PreloadingPhase.idle,
        totalIssues: 0,
        completedIssues: 0,
        isActive: false,
      ),
    );
  }
}

final issuesPreloaderProvider = AsyncNotifierProvider<
    IssuesPreloaderNotifier,
    PreloadingStatus
>(IssuesPreloaderNotifier.new);

// Провайдер для получения кешированных данных задачи
final cachedIssueProvider = Provider.family<IssueDataCache?, String>((ref, issueId) {
  final cache = ref.watch(issueDataCacheProvider);
  return cache[issueId];
});
