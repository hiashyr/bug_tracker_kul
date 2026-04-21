import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trying_flutter/routes/app_router.dart';
import 'package:trying_flutter/services/yandex_auth.dart';
import 'dart:html' as html;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Инициализировать Yandex Auth
  await YandexAuthService.init();

  // Обработка OAuth callback
  final hash = html.window.location.hash;
  if (hash.isNotEmpty && hash.contains('access_token')) {
    try {
      await YandexAuthService.handleAuthCallback(hash);
      // Очистить hash из URL для чистоты
      html.window.history.replaceState(null, '', html.window.location.pathname);
    } catch (e) {
      print('Ошибка обработки авторизации: $e');
    }
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