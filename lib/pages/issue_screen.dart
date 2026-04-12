import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/providers/status_provider.dart';
import '../providers/issue_provider.dart';
import '../providers/comment_provider.dart';
import '../widgets/issue_card.dart';
import '../widgets/comment_list.dart';
import '../widgets/comment_form.dart';
import '../widgets/qa_engineer_selector.dart';  // ← добавляем импорт

class IssueScreen extends ConsumerStatefulWidget {
  final String issueId;
  
  const IssueScreen({super.key, required this.issueId});

  @override
  ConsumerState<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
  bool _showQaSelector = false; 

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueProvider(widget.issueId));
    final commentsAsync = ref.watch(commentsProvider(widget.issueId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Задача ${widget.issueId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(issueProvider(widget.issueId));
              ref.invalidate(commentsProvider(widget.issueId));
              setState(() {
                _showQaSelector = false;  // скрываем селектор при обновлении
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Блок с задачей
          Expanded(
            flex: 2,
            child: issueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Ошибка: $error')),
              data: (issue) => SingleChildScrollView(
                child: Column(
                  children: [
                    IssueCard(
                      issue: issue,
                      onRefresh: () {
                        ref.invalidate(issueProvider(widget.issueId));
                      },
                      // ✅ При клике на кнопку показываем селектор
                      onTransitionToTesting: () {
                        setState(() {
                          _showQaSelector = true;
                        });
                      },
                    ),
                    
                    // ✅ ПОКАЗЫВАЕМ СЕЛЕКТОР QA ИНЖЕНЕРА (если нужно)
                    if (_showQaSelector)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: QaEngineerSelector(
                          issueId: widget.issueId,
                          onTransitionComplete: () {
                            // После успешного перехода обновляем данные
                            ref.invalidate(issueProvider(widget.issueId));
                            ref.invalidate(statusesProvider(widget.issueId));
                            setState(() {
                              _showQaSelector = false;  // скрываем селектор
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Блок с комментариями
          Expanded(
            flex: 3,
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Ошибка: $error')),
              data: (comments) => CommentList(
                comments: comments,
                onRefresh: () => ref.invalidate(commentsProvider(widget.issueId)),
              ),
            ),
          ),
          
          // Форма добавления комментария
          CommentForm(issueId: widget.issueId),
        ],
      ),
    );
  }
}