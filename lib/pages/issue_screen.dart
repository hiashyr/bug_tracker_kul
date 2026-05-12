import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/status.dart';
import '../providers/comment_provider.dart';
import '../providers/issue_provider.dart';
import '../providers/status_provider.dart';
import '../widgets/comment_form.dart';
import '../widgets/comment_list.dart';
import '../widgets/issue_card.dart';
import '../widgets/qa_engineer_selector.dart';

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

    return Column(
        children: [
          Expanded(
            flex: 2,
            child: issueAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Ошибка: $error'),
              ),
              data: (issue) {
                final availableStatuses = statusesAsync.whenOrNull(
                  data: (statuses) => statuses,
                );

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      IssueCard(
                        issue: issue,
                        onRefresh: _refreshIssueSection,
                        onTransitionToTesting: _showQaEngineerSelector,
                        availableStatuses: availableStatuses,
                        onStatusSelected: _handleStatusTransition,
                      ),
                      if (_showQaSelector)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: QaEngineerSelector(
                            issueId: widget.issueId,
                            onTransitionComplete: _handleQaTransitionComplete,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: commentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Ошибка: $error'),
              ),
              data: (comments) => CommentList(
                comments: comments,
                onRefresh: _refreshComments,
              ),
            ),
          ),
          CommentForm(issueId: widget.issueId),
        ],
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(issueProvider(widget.issueId));
    ref.invalidate(commentsProvider(widget.issueId));
    ref.invalidate(statusesProvider(widget.issueId));

    if (_showQaSelector) {
      setState(() {
        _showQaSelector = false;
      });
    }
  }

  Future<void> _refreshIssueSection() async {
    ref.invalidate(issueProvider(widget.issueId));
    ref.invalidate(statusesProvider(widget.issueId));
  }

  Future<void> _refreshComments() async {
    ref.invalidate(commentsProvider(widget.issueId));
  }

  void _showQaEngineerSelector() {
    if (!_showQaSelector) {
      setState(() {
        _showQaSelector = true;
      });
    }
  }

  void _hideQaEngineerSelector() {
    if (_showQaSelector) {
      setState(() {
        _showQaSelector = false;
      });
    }
  }

  Future<void> _handleQaTransitionComplete() async {
    _refreshIssueSection();
    _hideQaEngineerSelector();
  }

  Future<void> _handleStatusTransition(Status selectedStatus) async {
    if (selectedStatus.id == 'testing') {
      _showQaEngineerSelector();
      return;
    }

    final statusTransition = ref.read(statusTransitionProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await statusTransition(
        widget.issueId,
        selectedStatus.id,
        fieldValues: {},
      );

      if (!mounted) return;

      Navigator.pop(context);
      _refreshIssueSection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус изменен на "${selectedStatus.display}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}