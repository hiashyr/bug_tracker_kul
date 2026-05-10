import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/providers/auth_provider.dart';
import 'package:trying_flutter/services/yandex_auth.dart';
import 'package:trying_flutter/widgets/unauthorized_window.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final Widget? unauthorizedChild;

  const AuthGuard({
    super.key,
    required this.child,
    this.unauthorizedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    if (user == null) {
      return unauthorizedChild ??
          UnauthorizedView(
            onLoginPressed: () async {
              await YandexAuthService.loginWithYandex();
            },
          );
    }

    return child;
  }
}