import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/auth_provider.dart';
import 'package:trying_flutter/widgets/unauthorized_window.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authAuthorizerProvider);

    return authState.when(
      data: (isAuthorized) {
        if (!isAuthorized) {
          return UnauthorizedView(
            onLoginPressed: () async {
              final notifier = ref.read(authAuthorizerProvider.notifier);
              await notifier.login();
            },
          );
        }
        return child;
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ошибка авторизации: $error')),
    );
  }
}