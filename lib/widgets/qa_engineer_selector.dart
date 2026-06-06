import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/status_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class QaEngineerSelector extends ConsumerStatefulWidget {
  final String issueId;
  final VoidCallback onTransitionComplete;

  const QaEngineerSelector({
    super.key,
    required this.issueId,
    required this.onTransitionComplete,
  });

  @override
  ConsumerState<QaEngineerSelector> createState() => _QaEngineerSelectorState();
}

class _QaEngineerSelectorState extends ConsumerState<QaEngineerSelector> {
  User? _selectedEngineer;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(validUsersProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add, size: 18, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Перевод на тестирование',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          usersAsync.when(
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: LinearProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Ошибка загрузки пользователей: $error',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
            data: (users) => _buildContent(context, users),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<User> users) {
    if (users.isEmpty) {
      return Text(
        'Нет доступных QA инженеров',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.greyMedium,
        ),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<User>(
          value: _selectedEngineer,
          decoration: const InputDecoration(
            labelText: 'Выберите QA инженера',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: users.map((user) {
            return DropdownMenuItem<User>(
              value: user,
              child: _UserMenuItem(user: user),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (user) {
                  setState(() {
                    _selectedEngineer = user;
                  });
                },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _isLoading || _selectedEngineer == null ? null : _performTransition,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.textOnBrand,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnBrand,
                    ),
                  )
                : const Text('Перевести на тестирование'),
          ),
        ),
      ],
    );
  }

  Future<void> _performTransition() async {
    if (_selectedEngineer == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final statusTransition = ref.read(statusTransitionProvider);

      await statusTransition(
        widget.issueId,
        'testing',
        fieldValues: {
          'qaEngineer': _selectedEngineer!.login,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Задача переведена на тестирование'),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onTransitionComplete();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _UserMenuItem extends StatelessWidget {
  final User user;

  const _UserMenuItem({required this.user});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.display,
            style: AppTypography.issueSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            user.login,
            style: AppTypography.chipText.copyWith(
              color: AppColors.greyMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}