import 'package:flutter_test/flutter_test.dart';
import 'package:trying_flutter/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('должен корректно парсить JSON с полными данными', () {
      final json = {
        'login': 'ivanov',
        'display': 'Иван Иванов',
        'email': 'ivanov@example.com',
        'cloudUid': 'uid123456',
        'default_avatar_id': 'avatar123/medium',
      };

      final user = User.fromJson(json);

      expect(user.login, 'ivanov');
      expect(user.display, 'Иван Иванов');
      expect(user.email, 'ivanov@example.com');
      expect(user.cloudUid, 'uid123456');
      expect(user.defaultAvatarId, 'avatar123/medium');
    });

    test('должен парсить JSON бота без cloudUid', () {
      final json = {
        'login': 'tracker-bot',
        'display': 'Tracker Bot',
        'email': 'bot@example.com',
      };

      final user = User.fromJson(json);

      expect(user.login, 'tracker-bot');
      expect(user.display, 'Tracker Bot');
      expect(user.email, 'bot@example.com');
      expect(user.cloudUid, isNull);
      expect(user.defaultAvatarId, isNull);
    });

    test('должен парсить JSON с null default_avatar_id', () {
      final json = {
        'login': 'petrov',
        'display': 'Петр Петров',
        'email': 'petrov@example.com',
        'cloudUid': 'uid789',
        'default_avatar_id': null,
      };

      final user = User.fromJson(json);

      expect(user.defaultAvatarId, isNull);
    });

    test('должен игнорировать is_avatar_empty если он есть в JSON', () {
      final json = {
        'login': 'smirnov',
        'display': 'Смирнов',
        'email': 'smirnov@example.com',
        'cloudUid': 'uid000',
        'default_avatar_id': null,
        'is_avatar_empty': true,
      };

      final user = User.fromJson(json);

      expect(user.defaultAvatarId, isNull);
    });
  });

  group('User.avatarUrl', () {
    test('возвращает URL аватара когда defaultAvatarId задан', () {
      final user = User(
        login: 'ivanov',
        display: 'Иван Иванов',
        email: 'ivanov@example.com',
        cloudUid: 'uid123',
        defaultAvatarId: 'avatar123/medium',
      );

      expect(user.avatarUrl, 'https://avatars.yandex.net/get-yapic/avatar123/medium/islands-50');
    });

    test('возвращает null если defaultAvatarId пустая строка', () {
      final user = User(
        login: 'ivanov',
        display: 'Иван Иванов',
        email: 'ivanov@example.com',
        cloudUid: 'uid123',
        defaultAvatarId: '',
      );

      expect(user.avatarUrl, isNull);
    });

    test('возвращает null если defaultAvatarId null', () {
      final user = User(
        login: 'ivanov',
        display: 'Иван Иванов',
        email: 'ivanov@example.com',
        cloudUid: 'uid123',
        defaultAvatarId: null,
      );

      expect(user.avatarUrl, isNull);
    });
  });
}