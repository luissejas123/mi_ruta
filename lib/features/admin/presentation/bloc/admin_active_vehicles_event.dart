import 'package:equatable/equatable.dart';

abstract class AdminActiveVehiclesEvent extends Equatable {
  const AdminActiveVehiclesEvent();

  @override
  List<Object> get props => [];
}

/// Inicia el stream en tiempo real de unidades activas.
class WatchActiveVehicles extends AdminActiveVehiclesEvent {
  const WatchActiveVehicles();
}
