import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

void main() {
  group('AuthEntity notification settings', () {
    test('defaults to enabled when preferences are missing', () {
      final user = AuthEntity(
        uid: 'user-1',
        fullName: 'Usuario Test',
        email: 'user@test.com',
        governmentId: '1234567',
        phoneNumber: '1234567',
        role: 'user',
        createdAt: DateTime.now(),
      );

      expect(user.notificationPreferenceEnabled('trip'), isTrue);
      expect(user.notificationPreferenceEnabled('recharge'), isTrue);
      expect(user.notificationPreferenceEnabled('gift'), isTrue);
    });

    test('reads explicit preferences from settings map', () {
      final user = AuthEntity(
        uid: 'user-1',
        fullName: 'Usuario Test',
        email: 'user@test.com',
        governmentId: '1234567',
        phoneNumber: '1234567',
        role: 'user',
        createdAt: DateTime.now(),
        settings: {
          'notifications_enabled': true,
          'trip_notifications_enabled': true,
          'recharge_notifications_enabled': false,
          'gift_notifications_enabled': true,
        },
      );

      expect(user.notificationPreferenceEnabled('trip'), isTrue);
      expect(user.notificationPreferenceEnabled('recharge'), isFalse);
      expect(user.notificationPreferenceEnabled('gift'), isTrue);
      expect(user.notificationPreferenceEnabled('all'), isTrue);
    });
  });
}
