import 'package:mi_ruta/features/admin/data/datasources/admin_privileges_datasource.dart';
import 'package:mi_ruta/features/admin/domain/entities/admin_privileges.dart';

class AdminPrivilegesService {
  final AdminPrivilegesDatasource _datasource;

  AdminPrivilegesService({required AdminPrivilegesDatasource datasource})
    : _datasource = datasource;

  Future<AdminPrivileges> getPrivileges(String adminId) =>
      _datasource.getPrivileges(adminId);

  Future<void> savePrivileges(String adminId, AdminPrivileges privileges) =>
      _datasource.savePrivileges(adminId, privileges);
}
