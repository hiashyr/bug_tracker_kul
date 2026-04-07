import 'package:flutter/material.dart';
import '../models/issue.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onRefresh;

  const IssueCard({
    super.key,
    required this.issue,
    this.onRefresh,
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
            // ID и статус
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    issue.status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
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

            // Кнопка обновления (опционально)
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}