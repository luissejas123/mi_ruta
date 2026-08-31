import 'package:equatable/equatable.dart';

abstract class DriverAssignedRoutesEvent extends Equatable {
  const DriverAssignedRoutesEvent();

  @override
  List<Object?> get props => [];
}

class LoadDriverAssignedRoutes extends DriverAssignedRoutesEvent {
  final String driverId;

  const LoadDriverAssignedRoutes(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class SaveDriverAssignedRoute extends DriverAssignedRoutesEvent {
  final String driverId;
  final String routeId;

  const SaveDriverAssignedRoute({
    required this.driverId,
    required this.routeId,
  });

  @override
  List<Object?> get props => [driverId, routeId];
}
