import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../widgets/thumbnail_viewer.dart';

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

  Future<void> _attachFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;

    final xFile = result.files.first.xFile;
    final fileName = result.files.first.name;

    try {
      final bytes = await xFile.readAsBytes();
      final apiClient = ref.read(newApiClientProvider);
      await apiClient.uploadIssueAttachment(
        widget.issueId,
        bytes,
        filename: fileName,
      );
      if (!mounted) return;
      ref.invalidate(attachmentsProvider(widget.issueId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл прикреплён: $fileName'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка прикрепления файла: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueProvider(widget.issueId));
    final commentsAsync = ref.watch(commentsProvider(widget.issueId));
    final statusesAsync = ref.watch(statusesProvider(widget.issueId));
    final attachmentsAsync = ref.watch(attachmentsProvider(widget.issueId));

    return Column(
      children: [
        // Скроллящаяся область: информация о задаче + комментарии
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Карточка задачи
                Center(
                  child: issueAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Ошибка: $error')),
                    data: (issue) {
                      final availableStatuses = statusesAsync.whenOrNull(
                        data: (statuses) => statuses,
                      );

                      final attachmentsWidget = attachmentsAsync.when(
                        data: (attachments) {
                          return _AttachmentsSection(
                            issueId: widget.issueId,
                            attachments: attachments,
                            onAttachFile: _attachFile,
                          );
                        },
                        loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, _) => _AttachmentsSection(
                          issueId: widget.issueId,
                          attachments: const [],
                          onAttachFile: _attachFile,
                        ),
                      );

                      return Column(
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
                                onTransitionComplete:
                                    _handleQaTransitionComplete,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Комментарии - теперь часть одного скроллящегося потока
                commentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Ошибка: $error')),
                  data: (comments) => CommentList(
                    comments: comments,
                    onRefresh: _refreshComments,
                  ),
                ),

                // Пустое пространство, чтобы последний комментарий не скрывался формой
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Статическая форма внизу
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

    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (_) => const Center(child: CircularProgressIndicator()),
    // );

    try {
      await statusTransition(
        widget.issueId,
        selectedStatus.id,
        fieldValues: {},
      );

      if (!mounted) return;

      context.go('/');
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
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _AttachmentsSection extends ConsumerWidget {
  final String issueId;
  final List<Attachment> attachments;
  final VoidCallback? onAttachFile;

  const _AttachmentsSection({
    required this.issueId,
    required this.attachments,
    this.onAttachFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Прикреплённые файлы:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandBlue,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAttachFile,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Прикрепить файл'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Нет прикреплённых файлов',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final attachment = attachments[index];

                // Картинка, если есть thumbnail ИЛИ если расширение файла похоже на изображение
                final lowerName = attachment.name.toLowerCase();
                final isImage =
                    attachment.thumbnail != null ||
                    lowerName.endsWith('.png') ||
                    lowerName.endsWith('.jpg') ||
                    lowerName.endsWith('.jpeg') ||
                    lowerName.endsWith('.gif') ||
                    lowerName.endsWith('.webp');

                // URL картинки: если есть thumbnail — используем его, иначе — content
                final imageUrl = attachment.thumbnail != null
                    ? attachment.thumbnail!
                    : attachment.content;

                return GestureDetector(
                  onTap: () => showThumbnailPreview(
                    context,
                    ref,
                    imageUrl,
                    attachment.name,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isImage
                        ? ThumbnailTile(thumbnailUrl: imageUrl, size: 80)
                        : const Icon(
                            Icons.insert_drive_file,
                            size: 32,
                            color: Colors.grey,
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
