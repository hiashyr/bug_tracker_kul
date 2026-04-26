import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/routes/app_router.dart';
import 'package:trying_flutter/services/yandex_auth.dart';
import 'package:web/web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Проверяем, есть ли хеш с access_token (OAuth callback)
  final hash = window.location.hash;
  if (hash.contains('access_token')) {
    try {
      await YandexAuthService.handleAuthCallback(hash);
      // Очищаем хеш из URL после обработки
      window.location.href = '/';
    } catch (e) {
      print('Ошибка обработки OAuth callback: $e');
    }
  } else {
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