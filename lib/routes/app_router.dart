import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trying_flutter/pages/authCallbackScreen.dart';
import 'package:trying_flutter/pages/issue_screen.dart';
import 'package:trying_flutter/pages/issues_list_screen.dart';

/// Конфигурация маршрутов приложения
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'issues_list_screen',
      builder: (context, state) => const IssuesListScreen(),
    ),
    GoRoute(
      path: '/issue/:issueId',
      name: 'issue-detail',
      builder: (context, state) {
        final issueId = state.pathParameters['issueId']!;
        return IssueScreen(issueId: issueId);
      },
    ),
    GoRoute(
      path: '/auth/callback',
      name: 'auth-callback',
      builder: (context, state) => const AuthCallbackScreen(),
    ),
  ],
  // Обработка ошибок навигации
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
