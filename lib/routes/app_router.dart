import 'package:go_router/go_router.dart';
import 'package:trying_flutter/pages/issue_screen.dart';
import 'package:trying_flutter/pages/issues_list_screen.dart';
import 'package:trying_flutter/widgets/auth_guard.dart';
import 'package:trying_flutter/widgets/shell_scaffold.dart';

/// Конфигурация маршрутов приложения
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final isDetailPage = state.fullPath?.contains('/issue/') ?? false;
        return AuthGuard(
          child: ShellScaffold(
            showBackButton: isDetailPage,
            child: navigationShell,
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const IssuesListScreen(),
              routes: [
                GoRoute(
                  path: 'issue/:issueId',
                  name: 'issue-detail',
                  builder: (context, state) => IssueScreen(
                    issueId: state.pathParameters['issueId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);