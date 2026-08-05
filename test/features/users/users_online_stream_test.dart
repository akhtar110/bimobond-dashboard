import 'package:flutter_test/flutter_test.dart';
import 'package:bimo_bond_dashboard/features/users/data/datasources/users_presence_socket_service.dart';
import 'package:bimo_bond_dashboard/features/users/data/models/user_model.dart';
import 'package:bimo_bond_dashboard/features/users/data/datasources/users_remote_data_source.dart';

void main() {
  group('Users Online Stream & Presence Tests', () {
    test('UserPresenceChange parses online event correctly', () {
      final json = {
        'userId': 'user_123',
        'isOnline': true,
        'lastSeenAt': '2026-08-04T10:48:00.000Z',
      };

      final change = UserPresenceChange.fromJson(json, forceOnline: true);

      expect(change.userId, equals('user_123'));
      expect(change.isOnline, isTrue);
      expect(change.lastSeenAt, equals(DateTime.parse('2026-08-04T10:48:00.000Z')));
    });

    test('UserPresenceChange parses offline event correctly', () {
      final json = {
        'userId': 'user_456',
        'isOnline': false,
        'lastSeenAt': '2026-08-03T15:30:00.000Z',
      };

      final change = UserPresenceChange.fromJson(json, forceOnline: false);

      expect(change.userId, equals('user_456'));
      expect(change.isOnline, isFalse);
      expect(change.lastSeenAt, equals(DateTime.parse('2026-08-03T15:30:00.000Z')));
    });

    test('UserModel parses GET /users/admin/online user payload with location and count', () {
      final userJson = {
        "id": "user_123",
        "username": "johndoe",
        "fullName": "John Doe",
        "email": "john@example.com",
        "isVerified": true,
        "isBanned": false,
        "lastSeenAt": "2026-08-04T10:48:00.000Z",
        "isOnline": true,
        "lastLocation": {
          "city": "Riyadh",
          "region": "Riyadh Province",
          "country": "Saudi Arabia",
          "latitude": 24.7136,
          "longitude": 46.6753
        },
        "wallet": {
          "balance": 1500
        },
        "_count": {
          "posts": 12,
          "followers": 350,
          "following": 120
        }
      };

      final userModel = UserModel.fromJson(userJson);

      expect(userModel.id, equals('user_123'));
      expect(userModel.username, equals('johndoe'));
      expect(userModel.isVerified, isTrue);
      expect(userModel.isBanned, isFalse);
      expect(userModel.isOnline, isTrue);
      expect(userModel.lastActive, equals(DateTime.parse('2026-08-04T10:48:00.000Z')));
      expect(userModel.lastLocation?.city, equals('Riyadh'));
      expect(userModel.lastLocation?.region, equals('Riyadh Province'));
      expect(userModel.lastLocation?.country, equals('Saudi Arabia'));
      expect(userModel.followerCount, equals(350));
      expect(userModel.followingCount, equals(120));
      expect(userModel.postCount, equals(12));
    });

    test('UsersPageModel holds onlineCount correctly', () {
      final model = UsersPageModel(
        users: [],
        total: 150,
        page: 1,
        lastPage: 15,
        onlineCount: 42,
      );

      expect(model.onlineCount, equals(42));
      expect(model.total, equals(150));
      expect(model.page, equals(1));
      expect(model.lastPage, equals(15));
    });
  });
}
