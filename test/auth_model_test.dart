// Tests de AuthModel.fromJson: debe leer tanto el esquema snake_case como
// el camelCase que coexisten en la colección users de Firestore.

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/auth/data/models/auth_model.dart';

void main() {
  group('AuthModel.fromJson', () {
    test('lee esquema snake_case', () {
      final model = AuthModel.fromJson({
        'uid': 'uid_1',
        'full_name': 'Juan Pérez',
        'email': 'juan@miruta.com',
        'government_id': '1234567',
        'phone_number': '71234567',
        'profile_picture_url': 'https://img.png',
        'role': 'admin',
        'created_at': '2026-01-01T10:00:00.000',
        'wallet': {'current_balance': 12.0, 'currency': 'Bs'},
        'settings': {'dark_mode_enabled': true},
      });

      expect(model.fullName, 'Juan Pérez');
      expect(model.role, 'admin');
      expect(model.phoneNumber, '71234567');
      expect(model.createdAt.year, 2026);
    });

    test('lee esquema camelCase', () {
      final model = AuthModel.fromJson({
        'uid': 'uid_2',
        'fullName': 'María López',
        'email': 'maria@miruta.com',
        'governmentId': '7654321',
        'phoneNumber': '73333333',
        'profileImageUrl': 'https://img2.png',
        'userType': 'user',
        'createdAt': '2026-06-29T20:29:31.603786',
        'wallet': {'balance': 5.0, 'currency': 'Bs.'},
      });

      expect(model.fullName, 'María López');
      expect(model.role, 'user');
      expect(model.phoneNumber, '73333333');
      expect(model.createdAt.year, 2026);
    });

    test('role por defecto es user', () {
      final model = AuthModel.fromJson({'uid': 'uid_3', 'email': 'x@x.com'});

      expect(model.role, 'user');
    });

    test('toJson conserva el esquema snake_case', () {
      final model = AuthModel.fromJson({
        'uid': 'uid_1',
        'full_name': 'Juan',
        'email': 'juan@miruta.com',
        'role': 'admin',
        'created_at': '2026-01-01T10:00:00.000',
      });

      final json = model.toJson();

      expect(json['full_name'], 'Juan');
      expect(json['role'], 'admin');
      expect(json.containsKey('display_name'), isFalse);
    });
  });
}
