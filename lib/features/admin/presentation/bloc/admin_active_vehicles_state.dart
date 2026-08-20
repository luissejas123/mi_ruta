import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class AdminActiveVehiclesState extends Equatable {
  const AdminActiveVehiclesState();

  @override
  List<Object?> get props => [];
}

class AdminVehiclesInitial extends AdminActiveVehiclesState {
  const AdminVehiclesInitial();
}

class AdminVehiclesLoading extends AdminActiveVehiclesState {
  const AdminVehiclesLoading();
}

class AdminVehiclesLoaded extends AdminActiveVehiclesState {
  final List<VehicleEntity> vehicles;
  final Map<String, UserEntity> driversByUid;

  const AdminVehiclesLoaded(
      {required this.vehicles, required this.driversByUid});

  @override
  List<Object?> get props => [vehicles, driversByUid];
}

class AdminVehiclesError extends AdminActiveVehiclesState {
  final String message;

  const AdminVehiclesError({required this.message});

  @override
  List<Object?> get props => [message];
}
