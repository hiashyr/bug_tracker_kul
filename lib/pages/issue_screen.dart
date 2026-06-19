import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attachment.dart';
import '../models/status.dart';
import '../providers/attachments_provider.dart';
import '../providers/comment_provider.dart';
import '../providers/issue_provider.dart';
import '../providers/status_provider.dart';
import '../services/new_api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/comment_form.dart';
import '../widgets/comment_list.dart';
import '../widgets/fix_comment_dialog.dart';
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

  Future<void> _showFixCommentDialog() async {
    await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => FixCommentDialog(issueId: widget.issueId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueProvider(widget.issueId));
    final commentsAsync = ref.watch(commentsProvider(widget.issueId));
    final statusesAsync = ref.watch(statusesProvider(widget.issueId));
    final attachmentsAsync = ref.watch(attachmentsProvider(widget.issueId));

    return Column(
        children: [
          // Блок карточки задачи
          Center(
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

                  final attachmentsWidget = attachmentsAsync.when(
                    data: (attachments) {
                      if (attachments.isEmpty) return null;
                      return _AttachmentsSection(
                        issueId: widget.issueId,
                        attachments: attachments,
                      );
                    },
                    loading: () => null,
                    error: (_, __) => null,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        IssueCard(
                          issue: issue,
                          onRefresh: _refreshIssueSection,
                          onTransitionToTesting: _showQaEngineerSelector,
                          onFixRequested: _showFixCommentDialog,
                          availableStatuses: availableStatuses,
                          onStatusSelected: _handleStatusTransition,
                          attachmentsWidget: attachmentsWidget,
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

          // Блок комментариев - занимает всю доступную ширину
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

  Future<void> _refreshIssueSection() async {
    ref.invalidate(issueProvider(widget.issueId));
    ref.invalidate(statusesProvider(widget.issueId));
    ref.invalidate(attachmentsProvider(widget.issueId));
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
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _AttachmentsSection extends ConsumerWidget {
  final String issueId;
  final List<Attachment> attachments;

  const _AttachmentsSection({
    required this.issueId,
    required this.attachments,
  });

  // Future<void> _showImagePreview(BuildContext context, WidgetRef ref, Attachment attachment) async {
  //   if (attachment.thumbnail == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Миниатюра недоступна')),
  //     );
  //     return;
  //   }

  //   try {
  //     final apiClient = ref.read(newApiClientProvider);
  //     final bytes = await apiClient.fetchThumbnailBytes(attachment.thumbnail!);

  //     if (!context.mounted) return;

  //     showDialog(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         title: Text(attachment.name, style: const TextStyle(fontSize: 16)),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: InteractiveViewer(
  //             child: Image.memory(bytes),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(ctx).pop(),
  //             child: const Text('Закрыть'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Ошибка загрузки: $e')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прикреплённые файлы',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandBlue),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              final isImage = attachment.thumbnail != null;
              return GestureDetector(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage
                      ? _ThumbnailImage(thumbnailUrl: attachment.thumbnail!)
                      : const Icon(Icons.insert_drive_file, size: 32, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThumbnailImage extends ConsumerStatefulWidget {
  final String thumbnailUrl;

  const _ThumbnailImage({required this.thumbnailUrl});

  @override
  ConsumerState<_ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends ConsumerState<_ThumbnailImage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apiClient = ref.read(newApiClientProvider);
      final bytes = await apiClient.fetchThumbnailBytes(widget.thumbnailUrl);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover, width: 80, height: 80);
    }
    return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
  }
}