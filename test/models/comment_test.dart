import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/models/comment.dart';

void main() {
  group('Comment.fromJson', () {
    test('должен корректно парсить полный JSON', () {
      final json = {
        'text': 'Это тестовый комментарий',
        'createdAt': '2025-03-10T14:20:00.000+0000',
        'createdBy': {'display': 'Иван Иванов'},
        'updatedAt': '2025-03-11T09:00:00.000+0000',
        'updatedBy': {'display': 'Администратор'},
      };

      final comment = Comment.fromJson(json);

      expect(comment.text, 'Это тестовый комментарий');
      expect(comment.createdAt, DateTime.parse('2025-03-10T14:20:00.000+0000'));
      expect(comment.createdBy, 'Иван Иванов');
      expect(comment.updatedAt, DateTime.parse('2025-03-11T09:00:00.000+0000'));
      expect(comment.updatedBy, 'Администратор');
    });

    test('должен парсить JSON без updatedAt и updatedBy', () {
      final json = {
        'text': 'Комментарий без обновлений',
        'createdAt': '2025-03-10T14:20:00.000+0000',
        'createdBy': {'display': 'Иван Иванов'},
      };

      final comment = Comment.fromJson(json);

      expect(comment.text, 'Комментарий без обновлений');
      expect(comment.updatedAt, isNull);
      expect(comment.updatedBy, '');
    });
  });
}