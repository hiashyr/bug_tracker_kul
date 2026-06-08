import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/models/issue.dart';

void main() {
  group('Issue.fromJson', () {
    test('должен корректно парсить полный JSON', () {
      final json = {
        'id': 'DEV-123',
        'self': 'https://api.tracker.yandex.net/v3/issues/DEV-123',
        'summary': 'Тестовая задача',
        'description': 'Описание задачи',
        'status': {'display': 'Открыт'},
        'priority': {'display': 'Средний'},
        'createdAt': '2025-01-15T10:30:00.000+0000',
        'updatedAt': '2025-01-16T12:00:00.000+0000',
        'createdBy': {'display': 'Иван Иванов'},
        'qaEngineer': {'display': 'Петр Петров'},
      };

      final issue = Issue.fromJson(json);

      expect(issue.id, 'DEV-123');
      expect(issue.key, 'https://api.tracker.yandex.net/v3/issues/DEV-123');
      expect(issue.summary, 'Тестовая задача');
      expect(issue.description, 'Описание задачи');
      expect(issue.status, 'Открыт');
      expect(issue.priority, 'Средний');
      expect(issue.createdAt, DateTime.parse('2025-01-15T10:30:00.000+0000'));
      expect(issue.updatedAt, DateTime.parse('2025-01-16T12:00:00.000+0000'));
      expect(issue.createdBy, 'Иван Иванов');
      expect(issue.qaEngineer, 'Петр Петров');
    });

    test('должен парсить JSON без опциональных полей (description, updatedAt, qaEngineer)', () {
      final json = {
        'id': 'DEV-456',
        'self': 'https://api.tracker.yandex.net/v3/issues/DEV-456',
        'summary': 'Задача без описания',
        'status': {'display': 'В работе'},
        'priority': {'display': 'Высокий'},
        'createdAt': '2025-02-01T08:00:00.000+0000',
        'createdBy': {'display': 'Мария Петрова'},
      };

      final issue = Issue.fromJson(json);

      expect(issue.description, isNull);
      expect(issue.updatedAt, isNull);
      expect(issue.qaEngineer, isNull);
      expect(issue.id, 'DEV-456');
      expect(issue.status, 'В работе');
      expect(issue.createdBy, 'Мария Петрова');
    });

    test('должен корректно обрабатывать null в updatedAt', () {
      final json = {
        'id': 'DEV-789',
        'self': 'https://api.tracker.yandex.net/v3/issues/DEV-789',
        'summary': 'Задача',
        'status': {'display': 'Закрыт'},
        'priority': {'display': 'Низкий'},
        'createdAt': '2025-03-01T08:00:00.000+0000',
        'updatedAt': null,
        'createdBy': {'display': 'Анна Смирнова'},
      };

      final issue = Issue.fromJson(json);

      expect(issue.updatedAt, isNull);
    });

    test('должен парсить статус/приоритет/createdBy из вложенных объектов', () {
      final json = {
        'id': 'DEV-999',
        'self': 'https://api.tracker.yandex.net/v3/issues/DEV-999',
        'summary': 'Проверка вложенности',
        'status': {'id': '1', 'display': 'Новый'},
        'priority': {'id': '2', 'key': 'normal', 'display': 'Нормальный'},
        'createdAt': '2025-04-01T08:00:00.000+0000',
        'createdBy': {'id': '123', 'display': 'Тест Тестов'},
      };

      final issue = Issue.fromJson(json);

      expect(issue.status, 'Новый');
      expect(issue.priority, 'Нормальный');
      expect(issue.createdBy, 'Тест Тестов');
    });
  });
}