import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../models/issue.dart';
import '../models/status.dart';

class IssueDataCache {
  final Issue issue;
  final List<Status>? statuses;
  final List<Comment>? comments;
  final DateTime cachedAt;

  IssueDataCache({
    required this.issue,
    this.statuses,
    this.comments,
    required this.cachedAt,
  });

  IssueDataCache copyWith({
    Issue? issue,
    List<Status>? statuses,
    List<Comment>? comments,
    DateTime? cachedAt,
  }) {
    return IssueDataCache(
      issue: issue ?? this.issue,
      statuses: statuses ?? this.statuses,
      comments: comments ?? this.comments,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  bool get isIssueLoaded => issue.id.isNotEmpty;
  bool get areStatusesLoaded => statuses != null;
  bool get areCommentsLoaded => comments != null;
  bool get isFullyLoaded => isIssueLoaded && areStatusesLoaded && areCommentsLoaded;
}

class IssueDataCacheNotifier extends Notifier<Map<String, IssueDataCache>> {
  @override
  Map<String, IssueDataCache> build() {
    return {};
  }

  void setIssueData(Issue issue) {
    final existing = state[issue.id];
    state = {
      ...state,
      issue.id: (existing ?? IssueDataCache(
        issue: issue,
        cachedAt: DateTime.now(),
      )).copyWith(
        issue: issue,
        cachedAt: DateTime.now(),
      ),
    };
  }

  void setStatusesData(String issueId, List<Status> statuses) {
    final existing = state[issueId];
    if (existing != null) {
      state = {
        ...state,
        issueId: existing.copyWith(
          statuses: statuses,
          cachedAt: DateTime.now(),
        ),
      };
    }
  }

  void setCommentsData(String issueId, List<Comment> comments) {
    final existing = state[issueId];
    if (existing != null) {
      state = {
        ...state,
        issueId: existing.copyWith(
          comments: comments,
          cachedAt: DateTime.now(),
        ),
      };
    }
  }

  IssueDataCache? getCache(String issueId) {
    return state[issueId];
  }

  void clearCache(String issueId) {
    state = {...state}..remove(issueId);
  }

  void clearAllCache() {
    state = <String, IssueDataCache>{};
  }
}

final issueDataCacheProvider = NotifierProvider<
    IssueDataCacheNotifier,
    Map<String, IssueDataCache>
>(IssueDataCacheNotifier.new);
