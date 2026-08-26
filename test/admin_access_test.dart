// Tests de AdminAccessService y la extensión AuthAdminAccess.
// No dependen de Firebase ni BLoC.

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_permissions.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

AuthEntity _buildUser({
  String email = 'admin2@miruta.com',
  String role = 'admin',
  Map<String, dynamic>? settings,
}) {
  return AuthEntity(
    uid: 'uid_1',
    fullName: 'Admin',
    email: email,
    governmentId: '1',
    phoneNumber: '00000000',
    role: role,
    createdAt: DateTime(2026),
    settings: settings,
  );
}

void main() {
  group('AdminAccessService', () {
    test('SuperAdmin tiene acceso total aunque no tenga permisos', () {
      final user = _buildUser(
        email: 'admin@miruta.com',
        settings: null,
      );

      expect(AdminAccessService.isSuperAdmin(user.email), isTrue);
      expect(user.canManageUsers, isTrue);
      expect(user.canManageAdmins, isTrue);
      expect(user.canManagePermissions, isTrue);
      expect(user.canManageRoutes, isTrue);
    });

    test('admin con permisos activados puede acceder', () {
      final user = _buildUser(settings: {
        'dark_mode_enabled': false,
        'admin_permissions': {
          AdminPermissions.manageUsers: true,
          AdminPermissions.manageAdmins: false,
        },
      });

      expect(user.canManageUsers, isTrue);
      expect(user.canManageAdmins, isFalse);
    });

    test('admin sin admin_permissions no tiene permisos (sin excepción)', () {
      final user = _buildUser(settings: {'dark_mode_enabled': false});

      expect(user.canManageUsers, isFalse);
      expect(user.canManageAdmins, isFalse);
      expect(user.canManagePermissions, isFalse);
    });

    test('admin sin settings no tiene permisos (sin excepción)', () {
      final user = _buildUser(settings: null);

      expect(user.canManageUsers, isFalse);
      expect(user.canManageAdmins, isFalse);
    });

    test('usuario normal no tiene permisos', () {
      final user = _buildUser(email: 'user@miruta.com', role: 'user', settings: {
        'admin_permissions': {AdminPermissions.manageUsers: true},
      });

      expect(AdminAccessService.isSuperAdmin(user.email), isFalse);
      expect(user.canManageUsers, isFalse);
    });

    test('admin_permissions no-mapa no rompe la consulta', () {
      final user = _buildUser(settings: {'admin_permissions': 'mal'});

      expect(user.canManageUsers, isFalse);
    });
  });
}
