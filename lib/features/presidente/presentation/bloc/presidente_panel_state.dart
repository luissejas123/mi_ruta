import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class PresidentePanelState extends Equatable {
  const PresidentePanelState();

  @override
  List<Object?> get props => [];
}

class PresidentePanelLoading extends PresidentePanelState {
  const PresidentePanelLoading();
}

/// Agrega datos ya expuestos por AdminService/RouteService — sin capa de
/// datos propia (RQ-80): control de rutas y unidades en vivo (RQ-76) y
/// reporte operativo básico (RQ-77).
class PresidentePanelLoaded extends PresidentePanelState {
  final List<RouteEntity> activeRoutes;
  final List<VehicleEntity> activeVehicles;
  final List<VehicleEntity> allVehicles;
  final List<UserEntity> allUsers;

  const PresidentePanelLoaded({
    required this.activeRoutes,
    required this.activeVehicles,
    required this.allVehicles,
    required this.allUsers,
  });

  int get approvedVehicles =>
      allVehicles.where((v) => v.status == VehicleStatus.approved).length;
  int get pendingVehicles =>
      allVehicles.where((v) => v.status == VehicleStatus.pendingReview).length;
  int get rejectedVehicles =>
      allVehicles.where((v) => v.status == VehicleStatus.rejected).length;

  int get totalDrivers => allUsers.where((u) => u.userType == 'driver').length;
  int get totalPassengers => allUsers.where((u) => u.userType == 'passenger').length;
  int get totalTickeadores => allUsers.where((u) => u.userType == 'tickeador').length;
  int get blockedUsers => allUsers.where((u) => !u.isActive).length;

  /// Unidades activas agrupadas por línea (control de rutas en vivo, RQ-76).
  Map<String, int> get activeVehiclesByLine {
    final map = <String, int>{};
    for (final v in activeVehicles) {
      final line = v.lineNumber.isNotEmpty ? v.lineNumber : 'Sin línea';
      map[line] = (map[line] ?? 0) + 1;
    }
    return map;
  }

  @override
  List<Object?> get props => [activeRoutes, activeVehicles, allVehicles, allUsers];
}

class PresidentePanelError extends PresidentePanelState {
  final String message;

  const PresidentePanelError(this.message);

  @override
  List<Object?> get props => [message];
}
