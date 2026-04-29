import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/yandex_auth.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return AppBar(
      title: const Text('Задачи на тестирование'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [
        currentUserAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              child: Icon(Icons.person),
            ),
          ),
          data: (user) {
            return PopupMenuButton<String>(
              tooltip: 'Аккаунт',
              offset: const Offset(0, 40),
              onSelected: (value) async {
                if (value == 'logout') {
                  await YandexAuthService.logout();
                  ref.invalidate(authStateProvider);
                  ref.invalidate(currentUserProvider);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Выход из аккаунта'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                  child: user?.avatarUrl == null
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}