// lib/pages/issue_screen.dart (обновленная версия)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/issue_provider.dart';
import '../providers/comment_provider.dart';
import '../providers/status_provider.dart';
import '../widgets/issue_card.dart';
import '../widgets/comment_list.dart';
import '../widgets/comment_form.dart';
import '../widgets/qa_engineer_selector.dart';
import '../models/status.dart';

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
    final statusesAsync = ref.watch(statusesProvider(widget.issueId));

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
              ref.invalidate(statusesProvider(widget.issueId));
              setState(() {
                _showQaSelector = false;
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
              data: (issue) {
                // Получаем доступные статусы для текущей задачи
                final availableStatuses = statusesAsync.whenOrNull(
                  data: (statuses) => statuses,
                );
                
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      IssueCard(
                        issue: issue,
                        onRefresh: () {
                          ref.invalidate(issueProvider(widget.issueId));
                          ref.invalidate(statusesProvider(widget.issueId));
                        },
                        onTransitionToTesting: () {
                          setState(() {
                            _showQaSelector = true;
                          });
                        },
                        // ✅ Передаем доступные статусы
                        availableStatuses: availableStatuses,
                        // ✅ Обработчик выбора статуса
                        onStatusSelected: (selectedStatus) {
                          _handleStatusTransition(selectedStatus);
                        },
                      ),
                      
                      if (_showQaSelector)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: QaEngineerSelector(
                            issueId: widget.issueId,
                            onTransitionComplete: () {
                              ref.invalidate(issueProvider(widget.issueId));
                              ref.invalidate(statusesProvider(widget.issueId));
                              setState(() {
                                _showQaSelector = false;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
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

  // Обработчик выбора статуса
  Future<void> _handleStatusTransition(Status selectedStatus) async {
    // Показываем диалог загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final statusTransition = ref.read(statusTransitionProvider);
      
      // Для статуса testing используем специальную логику с выбором QA
      if (selectedStatus.id == 'testing') {
        Navigator.pop(context); // закрываем диалог
        setState(() {
          _showQaSelector = true;
        });
        return;
      }
      
      // Для остальных статусов выполняем переход
      await statusTransition(
        widget.issueId,
        selectedStatus.id,
        fieldValues: {},
      );

      if (mounted) {
        Navigator.pop(context); // закрываем диалог
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статус изменен на "${selectedStatus.display}"'),
            backgroundColor: Colors.green,
          ),
        );
        // Обновляем данные
        ref.invalidate(issueProvider(widget.issueId));
        ref.invalidate(statusesProvider(widget.issueId));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // закрываем диалог
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}