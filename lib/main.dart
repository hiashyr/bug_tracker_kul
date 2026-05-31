import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trying_flutter/models/user.dart';
import 'package:trying_flutter/routes/app_router.dart';
import 'package:trying_flutter/services/new_api_client.dart';
import 'package:trying_flutter/services/yandex_auth.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await dotenv.load(fileName: '.env');
  await YandexAuthService.init();

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

class NewDio extends ConsumerStatefulWidget {
  const NewDio({super.key});

  @override
  ConsumerState<NewDio> createState() => _NewDioState();
}

class _NewDioState extends ConsumerState<NewDio> {
  Future<void> _fetchUsers() async {
    try {
      final apiClient = ref.read(newApiClientProvider);
      final users = await apiClient.fetchUsers();
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Пользователи'),
          content: Text('Получено пользователей: ${users.length}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _fetchUsers,
          child: const Text('Test Dio Request'),
        ),
      ],
    );
  }
}
