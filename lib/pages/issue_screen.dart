import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/models/status.dart';
import 'package:trying_flutter/providers/status_provider.dart';
import 'package:trying_flutter/widgets/comment_form.dart';
import '../providers/issue_provider.dart';
import '../providers/comment_provider.dart';
import '../widgets/issue_card.dart';
import '../widgets/comment_list.dart';

class IssueScreen extends ConsumerWidget {
  final String issueId;
  
  const IssueScreen({super.key, required this.issueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueAsync = ref.watch(issueProvider(issueId));
    final commentsAsync = ref.watch(commentsProvider(issueId));
    final statusesAsync = ref.watch(statusesProvider(issueId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Задача $issueId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(issueProvider(issueId));
              ref.invalidate(commentsProvider(issueId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Блок с задачей
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: issueAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки задачи: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(issueProvider(issueId));
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
                data: (issue) => IssueCard(
                  issue: issue,
                  onRefresh: () => ref.invalidate(issueProvider(issueId)),
                ),
              ),
            ),
          ),
          
          // Блок с комментариями
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: commentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки комментариев: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(commentsProvider(issueId));
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
                data: (comments) => CommentList(
                  comments: comments,
                  onRefresh: () => ref.invalidate(commentsProvider(issueId)),
                ),
              ),
            ),
          ),
          
          // Форма добавления комментария
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CommentForm(issueId: issueId),
          ),
          
          // Блок со статусами
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: statusesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Ошибка загрузки статусов: $error'),
              data: (statuses) => _buildStatusChips(statuses),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(List<Status> statuses) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: statuses.map((status) {
        return ActionChip(
          label: Text(status.display),
          onPressed: () {
            // TODO: изменить статус задачи
            print('Изменить статус на: ${status.id}');
          },
        );
      }).toList(),
    );
  }
}