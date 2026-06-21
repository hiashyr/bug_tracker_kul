import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/comment_provider.dart';
import '../theme/app_colors.dart';

class CommentForm extends ConsumerStatefulWidget {
  final String issueId;

  const CommentForm({super.key, required this.issueId});

  @override
  ConsumerState<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends ConsumerState<CommentForm> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_isSubmitting) return;

    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст комментария')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final addComment = ref.read(addCommentProvider);
      await addComment(widget.issueId, text);

      if (!mounted) return;

      _controller.clear();
      _focusNode.requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Комментарий добавлен'),
        backgroundColor: Colors.green,),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandBlueLight,
        border: Border(top: BorderSide(color: AppColors.greyLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                maxLength: 1000,
                onSubmitted: (_) => _sendComment(),
                decoration: const InputDecoration(
                  hintText: 'Напишите комментарий...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmitting ? null : _sendComment,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnBrand,
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.textOnBrand),
          ),
        ],
      ),
    );
  }
}