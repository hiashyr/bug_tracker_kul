import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_quill/markdown_quill.dart';
import '../models/attachment.dart';
import '../providers/comment_provider.dart';
import '../providers/status_provider.dart';
import '../providers/upload_provider.dart';
import '../theme/app_colors.dart';

class FixCommentDialog extends ConsumerStatefulWidget {
  final String issueId;

  const FixCommentDialog({super.key, required this.issueId});

  @override
  ConsumerState<FixCommentDialog> createState() => _FixCommentDialogState();
}

class _FixCommentDialogState extends ConsumerState<FixCommentDialog> {
  late final QuillController _quillController;
  final List<Attachment> _attachments = [];

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
      addComment(
        widget.issueId,
        markdown,
        attachmentIds: _attachments.isNotEmpty ? _attachments.map((a) => a.id).toList() : null,
      ),
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
                    color: AppColors.backgroundDark,
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
                config: QuillSimpleToolbarConfig(
                  color: AppColors.brandBlue,
                  showDirection: false,
                  showHeaderStyle: true,
                  multiRowsDisplay: false,
                  showCodeBlock: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showQuote: true,
                  showLink: true,
                  showFontFamily: false,
                  showFontSize: false,
                  showColorButton : false,
                  showBackgroundColorButton : false,
                  showSubscript: false,
                  showSuperscript: false,
                  showSearchButton: false,
                  customButtons: [
                    QuillToolbarCustomButtonOptions(
                      icon: const Icon(Icons.table_chart),
                      tooltip: 'Таблица',
                      onPressed: () {
                        debugPrint('Table button pressed (stub)');
                      },
                    ),
                    QuillToolbarCustomButtonOptions(
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Прикрепить файл',
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
                        if (result != null) {
                          final xFile = result.files.first.xFile;
                          final fileName = result.files.first.name;
                          try {
                            final bytes = await xFile.readAsBytes();
                            final uploadFile = ref.read(uploadFileProvider);
                            final attachment = await uploadFile(
                              bytes,
                              filename: fileName,
                            );
                            if (context.mounted) {
                              setState(() {
                                _attachments.add(attachment);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Файл прикреплён: $fileName')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка загрузки файла: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
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
