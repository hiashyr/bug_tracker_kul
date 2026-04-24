import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/routes/app_router.dart';
import 'package:trying_flutter/services/yandex_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // ⭐ ВАЖНО: Обработать callback ДО инициализации GoRouter
  final hash = html.window.location.hash;
  if (hash.isNotEmpty && hash.contains('access_token')) {
    try {
      await YandexAuthService.handleAuthCallback(hash);
      // ⭐ Очистить hash из URL для чистоты
      html.window.history.replaceState(null, '', '/');
    } catch (e) {
      print('Ошибка обработки авторизации: $e');
      // Очистить hash даже при ошибке
      html.window.history.replaceState(null, '', '/');
    }
  }

  // Инициализировать YandexAuthService только если нет callback
  if (!hash.contains('access_token')) {
    await YandexAuthService.init();
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Yandex Tracker Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}