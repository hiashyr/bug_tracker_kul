import 'package:flutter/material.dart';
import 'package:trying_flutter/theme/app_theme.dart';
import '../models/issue.dart';
import '../models/status.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onRefresh;
  final VoidCallback? onTransitionToTesting;
  final List<Status>? availableStatuses;
  final ValueChanged<Status>? onStatusSelected;

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IssueHeader(
              issue: issue,
              availableStatuses: availableStatuses,
              onStatusSelected: onStatusSelected,
            ),
            const SizedBox(height: 16),
            IssueDetails(issue: issue),
            const SizedBox(height: 12),
            IssueActions(
              issue: issue,
              onTransitionToTesting: onTransitionToTesting,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

class IssueHeader extends StatelessWidget {
  final Issue issue;
  final List<Status>? availableStatuses;
  final ValueChanged<Status>? onStatusSelected;

  const IssueHeader({
    super.key,
    required this.issue,
    this.availableStatuses,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasTransitions =
        availableStatuses != null && availableStatuses!.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          issue.id,
          style: AppTypography.issueId,
        ),
        _StatusChip(
          status: issue.status,
          hasTransitions: hasTransitions,
          onTap: hasTransitions ? () => _showStatusMenu(context) : null,
          color: _getStatusColor(issue.status),
        ),
      ],
    );
  }

  void _showStatusMenu(BuildContext context) {
    final statuses = availableStatuses;
    if (statuses == null || statuses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Изменить статус',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...statuses.map((status) {
                return ListTile(
                  leading: Icon(
                    _getStatusIcon(status.display),
                    color: _getStatusColor(status.display),
                  ),
                  title: Text(status.display),
                  onTap: () {
                    Navigator.pop(sheetContext);
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
        return AppColors.statusOpen;
      case 'в работе':
      case 'in progress':
        return AppColors.statusInProgress;
      case 'на тестировании':
      case 'testing':
        return AppColors.statusTesting;
      case 'закрыт':
      case 'closed':
        return AppColors.statusClosed;
      default:
        return AppColors.statusTesting;
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
}

class IssueDetails extends StatelessWidget {
  final Issue issue;

  const IssueDetails({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabelText('Приоритет:'),
        Text(
          issue.priority,
          style: AppTypography.issueDescription,
        ),
        const SizedBox(height: 12),
        const _LabelText('Название:'),
        Text(
          issue.summary ?? 'Нет названия',
          style: AppTypography.issueSummary,
        ),
        const SizedBox(height: 12),
        if (issue.description != null) ...[
          const _LabelText('Описание:'),
          Text(
            issue.description!,
            style: AppTypography.issueDescription,
          ),
          const SizedBox(height: 12),
        ],
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Создал: ${issue.createdBy}',
          style: AppTypography.caption,
        ),
        Text(
          'Дата: ${_formatDate(issue.createdAt)}',
          style: AppTypography.caption,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}

class _LabelText extends StatelessWidget {
  final String text;

  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label,
    );
  }
}

class IssueActions extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTransitionToTesting;
  final VoidCallback? onRefresh;

  const IssueActions({
    super.key,
    required this.issue,
    this.onTransitionToTesting,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isTesting = issue.status.toLowerCase() == 'testing' ||
        issue.status.toLowerCase() == 'на тестировании';

    return Column(
      children: [
        if (!isTesting && onTransitionToTesting != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTransitionToTesting,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Перевести на тестирование'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.textOnBrand,
              ),
            ),
          ),
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool hasTransitions;
  final VoidCallback? onTap;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.hasTransitions,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasTransitions
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
            status,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: AppColors.greyDark,
            ),
          ),
          if (hasTransitions) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColors.greyDark,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;

    return GestureDetector(
      onTap: onTap,
      child: chip,
    );
  }
}