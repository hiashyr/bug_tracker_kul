import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/models/status.dart';

void main() {
  group('Status.fromJson', () {
    test('должен корректно парсить JSON', () {
      final json = {
        'id': 'transition_to_review',
        'display': 'Отправить на ревью',
      };

      final status = Status.fromJson(json);

      expect(status.id, 'transition_to_review');
      expect(status.display, 'Отправить на ревью');
    });
  });
}