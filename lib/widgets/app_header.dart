import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:trying_flutter/providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_typography.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return AppBar(
      title: const Text('Bug Tracker'),
      actions: [
        currentUserAsync.when(
          data: (user) {
            if (user == null) return const _DefaultAvatar();
            return _UserAvatarWithLogout(user: user, ref: ref);
          },
          loading: () => const _LoadingAvatar(),
          error: (error, stack) => const _DefaultAvatar(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Отдельный виджет для loading состояния
class _LoadingAvatar extends StatelessWidget {
  const _LoadingAvatar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }
}

// Дефолтный аватар при ошибке
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 16),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, size: 18, color: Colors.white),
      ),
    );
  }
}

// Аватар пользователя с кнопкой выхода справа
class _UserAvatarWithLogout extends StatelessWidget {
  const _UserAvatarWithLogout({required this.user, required this.ref});

  final User user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    user.display.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          tooltip: 'Выйти',
          onPressed: () async {
            final authNotifier = ref.read(authAuthorizerProvider.notifier);
            await authNotifier.logout();
          },
        ),
      ],
    );
  }
}
