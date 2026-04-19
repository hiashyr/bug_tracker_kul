// lib/widgets/issue_card.dart
import 'package:flutter/material.dart';
import '../models/issue.dart';
import '../models/status.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onRefresh;
  final VoidCallback? onTransitionToTesting;
  final List<Status>? availableStatuses;  // ← добавляем список доступных статусов
  final Function(Status)? onStatusSelected;  // ← колбэк при выборе статуса

  const IssueCard({
    super.key,
    required this.issue,
    this.onRefresh,
    this.onTransitionToTesting,
    this.availableStatuses,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID и статус (статус теперь кликабельный)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  issue.self,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // ✅ КЛИКАБЕЛЬНЫЙ СТАТУС
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: 16),

            // Приоритет
            const Text(
              'Приоритет:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(issue.priority),
            const SizedBox(height: 12),

            // Название задачи
            const Text(
              'Название:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              issue.summary ?? "Нет названия",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Описание (если есть)
            if (issue.description != null) ...[
              const Text(
                'Описание:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                issue.description!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            // Автор и дата создания
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Создал: ${issue.createdBy}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Дата: ${_formatDate(issue.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 12),

            // Кнопка перевода на тестирование (оставляем для быстрого доступа)
            if (issue.status.toLowerCase() != 'testing' &&
                issue.status.toLowerCase() != 'на тестировании')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTransitionToTesting,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Перевести на тестирование'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            // Кнопка обновления
            if (onRefresh != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Обновить'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Виджет кликабельного статуса
  Widget _buildStatusChip(BuildContext context) {
    final hasTransitions = availableStatuses != null && availableStatuses!.isNotEmpty;
    
    return GestureDetector(
      onTap: hasTransitions ? () => _showStatusMenu(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: _getStatusColor(issue.status),
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasTransitions
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              issue.status,
              style: const TextStyle(color: Colors.white),
            ),
            if (hasTransitions) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Показываем меню выбора статуса
  void _showStatusMenu(BuildContext context) {
    if (availableStatuses == null || availableStatuses!.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Изменить статус',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...availableStatuses!.map((status) {
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(status.display),
                    color: _getStatusColor(status.display),
                  ),
                  title: Text(status.display),
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected?.call(status);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'открыт':
      case 'open':
        return Colors.green;
      case 'в работе':
      case 'in progress':
        return Colors.blue;
      case 'на тестировании':
      case 'testing':
        return Colors.orange;
      case 'закрыт':
      case 'closed':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'открыт':
      case 'open':
        return Icons.lock_open;
      case 'в работе':
      case 'in progress':
        return Icons.engineering;
      case 'на тестировании':
      case 'testing':
        return Icons.checklist;
      case 'закрыт':
      case 'closed':
        return Icons.lock;
      default:
        return Icons.timeline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}