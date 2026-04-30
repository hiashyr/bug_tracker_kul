import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/pages/issue_screen.dart';
import 'package:trying_flutter/pages/issues_list_screen.dart';

/// Конфигурация маршрутов приложения
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const IssuesListScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'issue/:issueId',
          name: 'issue-detail',
          builder: (BuildContext context, GoRouterState state) {
            final issueId = state.pathParameters['issueId']!;
            return IssueScreen(issueId: issueId);
          },
        ),
      ],
    ),
  ],
);