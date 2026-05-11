import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:trying_flutter/providers/user_provider.dart';
import '../providers/auth_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    //TO DO: Переделать аватар. Уже ничего не сооброжаю
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final url = user.avatarUrl;
        if (url == null) {
          return CircleAvatar(
            child: Text(user.display.substring(0, 1).toUpperCase()),
          );
        }

        return CircleAvatar(
          backgroundImage: NetworkImage(url),
        );
      },
      loading: () => const CircleAvatar(child: CircularProgressIndicator()),
      error: (error, stack) => CircleAvatar(
        backgroundColor: Colors.red,
        child: Text('!'),
      ),
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

// Меню с аватаром пользователя
class _UserAvatarMenu extends StatelessWidget {
  const _UserAvatarMenu({required this.user, required this.ref});

  final User user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, kToolbarHeight),
        onSelected: (value) async {
          if (value == 'logout') {
            final authNotifier = ref.read(authAuthorizerProvider.notifier);
            await authNotifier.logout();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.display.isNotEmpty ? user.display : user.login,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email.isNotEmpty)
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[100],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem(value: 'logout', child: Text('Выйти')),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // Используем логику из модели User
    final avatarUrl = user.avatarUrl;

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white24,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? const Icon(Icons.person, size: 20, color: Colors.white)
          : null,
    );
  }
}
