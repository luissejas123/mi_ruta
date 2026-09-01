import 'package:flutter_test/flutter_test.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_permissions.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_access_service.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

void main() {
  final baseAdmin = AuthEntity(
    uid: 'admin-1',
    fullName: 'Admin',
    email: 'admin@test.com',
    governmentId: '123',
    phoneNumber: '70000000',
    role: 'admin',
    createdAt: DateTime(2024),
    settings: {
      'admin_permissions': {
        AdminPermissions.manageUsers: true,
        AdminPermissions.manageAdmins: false,
        AdminPermissions.managePermissions: false,
        AdminPermissions.manageRoutes: true,
      },
    },
  );

  test('un admin sin permisos no ve operaciones no habilitadas', () {
    final available = AdminAccessService.getAvailableOperations(baseAdmin);

    expect(
      available.map((op) => op.permissionKey).toList(),
      containsAll([AdminPermissions.manageUsers, AdminPermissions.manageRoutes]),
    );
    expect(
      available.map((op) => op.permissionKey).toList(),
      isNot(contains(AdminPermissions.manageAdmins)),
    );
    expect(
      available.map((op) => op.permissionKey).toList(),
      isNot(contains(AdminPermissions.managePermissions)),
    );
  });

  test('el superadmin tiene acceso a todas las operaciones', () {
    final superAdmin = AuthEntity(
      uid: 'sa-1',
      fullName: 'Superadmin',
      email: 'super@test.com',
      governmentId: '777',
      phoneNumber: '71111111',
      role: 'admin',
      createdAt: DateTime(2024),
      isSuperAdmin: true,
    );

    final available = AdminAccessService.getAvailableOperations(superAdmin);
    expect(
      available,
      containsAll(AdminOperation.values),
    );
  });

  test('las operaciones se resuelven por permisos reales', () {
    expect(
      AdminAccessService.canAccessOperation(
        baseAdmin,
        AdminOperation.manageUsers,
      ),
      isTrue,
    );
    expect(
      AdminAccessService.canAccessOperation(
        baseAdmin,
        AdminOperation.manageAdmins,
      ),
      isFalse,
    );
    expect(
      AdminAccessService.canAccessOperation(
        baseAdmin,
        AdminOperation.managePermissions,
      ),
      isFalse,
    );
  });
}
