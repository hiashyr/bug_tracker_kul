import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_quill/markdown_quill.dart';
import '../providers/comment_provider.dart';
import '../providers/status_provider.dart';
import '../theme/app_colors.dart';

class FixCommentDialog extends ConsumerStatefulWidget {
  final String issueId;

  const FixCommentDialog({super.key, required this.issueId});

  @override
  ConsumerState<FixCommentDialog> createState() => _FixCommentDialogState();
}

class _FixCommentDialogState extends ConsumerState<FixCommentDialog> {
  late final QuillController _quillController;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void _submit() {
    final delta = _quillController.document.toDelta();
    final markdown = DeltaToMarkdown().convert(delta);

    final addErrorComment = ref.read(addErrorCommentProvider);
    final addComment = ref.read(addCommentProvider);
    final statusTransition = ref.read(statusTransitionProvider);

    Future.wait([
      addErrorComment(markdown),
      addComment(widget.issueId, markdown),
      statusTransition(widget.issueId, 'tested'),
    ]);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Комментарий к исправлению',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: QuillSimpleToolbar(
                controller: _quillController,
                config: const QuillSimpleToolbarConfig(
                  color: AppColors.brandBlue,
                  // sectionDividerColor: AppColors.greyDark,
                  showDirection: false,
                  showHeaderStyle: true,
                  multiRowsDisplay: false,
                  showCodeBlock: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showQuote: true,
                  showLink: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                controller: _quillController,
                config: const QuillEditorConfig(
                  placeholder: 'Опишите, что нужно исправить...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textOnBrand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Отправить описание ошибки'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
