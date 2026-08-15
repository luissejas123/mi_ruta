import 'package:mi_ruta/features/admin/data/datasources/user_management_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Servicio neutral de gestión de cuentas, compartido por la pantalla de
/// aprobación de choferes y el panel de administración/presidencia
/// (RQ-71 gestión de usuarios, RQ-72 aprobación).
class UserManagementService {
  final UserManagementDatasource _datasource;

  UserManagementService({required UserManagementDatasource datasource})
      : _datasource = datasource;

  Future<List<UserEntity>> getUsers({String? userTypeFilter}) =>
      _datasource.getUsers(userTypeFilter: userTypeFilter);

  Future<void> setUserActive(String uid, bool isActive) =>
      _datasource.setUserActiveState(uid, isActive);

  Future<void> setQaAccess(String uid, bool qaAccess) =>
      _datasource.setQaAccess(uid, qaAccess);
}
