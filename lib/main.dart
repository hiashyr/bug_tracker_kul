import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  String _markdownPreview = '';
  final DeltaToMarkdown _deltaToMarkdown = DeltaToMarkdown();

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    _quillController.addListener(_updateMarkdownPreview);
    _updateMarkdownPreview();
  }

  void _updateMarkdownPreview() {
    final Delta delta = _quillController.document.toDelta();
    final String markdown = _deltaToMarkdown.convert(delta);

    setState(() {
      _markdownPreview = markdown;
    });
  }

  void _submit() {
    final Delta delta = _quillController.document.toDelta();
    final List<Map<String, dynamic>> deltaJson = delta.toJson();
    final String markdown = _deltaToMarkdown.convert(delta);

    debugPrint('Delta JSON: ${deltaJson.length} ops');
    debugPrint('Markdown: $markdown');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delta JSON: ${deltaJson.length} ops\nMarkdown отправлен.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _quillController.removeListener(_updateMarkdownPreview);
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Comment Form (Quill)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Тулбар: убираем лишний SingleChildScrollView
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
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: const QuillEditorConfig(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Markdown Preview:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: _markdownPreview.isEmpty
                        ? 'Пишите текст в редакторе, чтобы увидеть Markdown-превью.'
                        : _markdownPreview,
                    softLineBreak: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
      ),
    );
  }
}