import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/data/datasources/driver_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

/// Orquesta las capacidades de administración/presidencia (RQ-71 a RQ-77):
/// gestión de usuarios (delegada a UserManagementService) + unidades.
/// Sin capa de datos propia para unidades: reusa DriverDatasource, que ya
/// modela la colección `vehicles`.
class AdminService {
  final UserManagementService _userManagementService;
  final DriverDatasource _driverDatasource;

  AdminService({
    required UserManagementService userManagementService,
    required DriverDatasource driverDatasource,
  })  : _userManagementService = userManagementService,
        _driverDatasource = driverDatasource;

  Future<List<UserEntity>> getUsers({String? userTypeFilter}) =>
      _userManagementService.getUsers(userTypeFilter: userTypeFilter);

  Future<void> setUserActive(String uid, bool isActive) =>
      _userManagementService.setUserActive(uid, isActive);

  /// Unidades actualmente en servicio (RQ-75).
  Future<List<VehicleEntity>> getActiveVehicles() => _driverDatasource.getActiveVehicles();

  /// Todas las unidades registradas (para reportes operativos, RQ-77).
  Future<List<VehicleEntity>> getAllVehicles() => _driverDatasource.getAllVehicles();
}
