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

  /// Asigna una ruta al perfil del chofer (RQ4-PRE), no a la unidad.
  Future<void> assignRouteToDriver(String uid, String routeRef) =>
      _datasource.assignRouteToDriver(uid, routeRef);

  Future<void> setUserActive(String uid, bool isActive) =>
      _datasource.setUserActiveState(uid, isActive);

  /// Cola de solicitudes de chofer sin resolver (RQ4: "registrarme como chofer").
  Future<List<UserEntity>> getPendingDriverRequests() =>
      _datasource.getPendingDriverRequests();

  /// El propio usuario solicita ser chofer. No cambia su `role`.
  Future<void> requestDriverRole(String uid) =>
      _datasource.requestDriverRole(uid);

  /// Aprueba o rechaza una solicitud. Al aprobar, promueve a `driver`.
  Future<void> resolveDriverRequest(String uid, {required bool approved}) =>
      _datasource.resolveDriverRequest(uid, approved: approved);

  /// Asigna el rol `tickeador` con su estación y líneas de operación.
  Future<void> assignTickeador(
    String uid, {
    required String assignedStation,
    required List<String> assignedLines,
  }) =>
      _datasource.assignTickeador(
        uid,
        assignedStation: assignedStation,
        assignedLines: assignedLines,
      );
}
