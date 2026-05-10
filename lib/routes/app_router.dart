import 'package:go_router/go_router.dart';
import 'package:trying_flutter/pages/issue_screen.dart';
import 'package:trying_flutter/pages/issues_list_screen.dart';
import 'package:trying_flutter/widgets/auth_guard.dart';

/// Конфигурация маршрутов приложения
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => AuthGuard(child: const IssuesListScreen()),
      routes: <RouteBase>[
        GoRoute(
          path: 'issue/:issueId',
          name: 'issue-detail',
          builder: (context, state) => AuthGuard(
            child: IssueScreen(issueId: state.pathParameters['issueId']!),
          ),
        ),
      ],
    ),
  ],
);
