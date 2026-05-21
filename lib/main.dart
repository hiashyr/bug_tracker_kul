import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
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
    return MaterialApp(
      title: 'Quill Markdown Comment Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final QuillController _quillController;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
  }

  void _submit() {
    final Delta delta = _quillController.document.toDelta();
    final List<Map<String, dynamic>> deltaJson = delta.toJson();

    debugPrint('Delta JSON: ${deltaJson.length} ops');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delta JSON: ${deltaJson.length} ops\nОтправлено.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Comment Form (Quill)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Тулбар
            SizedBox(
              height: 48,
              child: QuillSimpleToolbar(
                controller: _quillController,
                config: const QuillSimpleToolbarConfig(
                  showDirection: false,
                  showHeaderStyle: true,
                  multiRowsDisplay: false,
                  showCodeBlock: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showQuote: true,
                  showLink: true,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Редактор
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка отправки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Отправить комментарий'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}