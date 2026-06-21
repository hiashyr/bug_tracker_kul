import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class UnauthorizedView extends StatelessWidget {
  const UnauthorizedView({
    super.key,
    required this.onLoginPressed,
  });

  final Future<void> Function() onLoginPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи на тестирование'),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textOnBrand,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.greyMedium),
            const SizedBox(height: 16),
            Text(
              'Для просмотра задач нужно войти через Яндекс',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: AppColors.greyMedium,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await onLoginPressed();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка авторизации: $e'),
                    backgroundColor: AppColors.error,),
                  );
                }
              },
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}