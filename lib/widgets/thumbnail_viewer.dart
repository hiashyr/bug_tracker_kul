import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/theme/app_colors.dart';

import '../services/new_api_client.dart';

/// Показывает миниатюру изображения (загружается асинхронно).
class ThumbnailTile extends ConsumerStatefulWidget {
  final String thumbnailUrl;
  final double size;

  const ThumbnailTile({
    super.key,
    required this.thumbnailUrl,
    this.size = 40,
  });

  @override
  ConsumerState<ThumbnailTile> createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends ConsumerState<ThumbnailTile> {
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
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          _bytes!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        ),
      );
    }
    return Icon(Icons.broken_image, size: widget.size * 0.75, color: Colors.grey);
  }
}

/// Открывает диалог с полноразмерным предпросмотром изображения.
Future<void> showThumbnailPreview(
  BuildContext context,
  WidgetRef ref,
  String thumbnailUrl,
  String fileName,
) async {
  try {
    final apiClient = ref.read(newApiClientProvider);
    final bytes = await apiClient.fetchThumbnailBytes(thumbnailUrl);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fileName, style: const TextStyle(fontSize: 16, color: AppColors.brandBlue)),
        content: SizedBox(
          width: double.maxFinite,
          child: InteractiveViewer(
            child: Image.memory(bytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка загрузки: $e'),
      backgroundColor: AppColors.error,),
    );
  }
}