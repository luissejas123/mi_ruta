import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class DriverAssignedRoutesState extends Equatable {
  const DriverAssignedRoutesState();

  @override
  List<Object?> get props => [];
}

class DriverAssignedRoutesInitial extends DriverAssignedRoutesState {}

class DriverAssignedRoutesLoading extends DriverAssignedRoutesState {}

class DriverAssignedRoutesLoaded extends DriverAssignedRoutesState {
  final List<RouteEntity> routes;

  const DriverAssignedRoutesLoaded(this.routes);

  @override
  List<Object?> get props => [routes];
}

class DriverAssignedRoutesSaving extends DriverAssignedRoutesState {
  final List<RouteEntity> routes;

  const DriverAssignedRoutesSaving(this.routes);

  @override
  List<Object?> get props => [routes];
}

class DriverAssignedRoutesSaved extends DriverAssignedRoutesState {
  final List<RouteEntity> routes;

  const DriverAssignedRoutesSaved(this.routes);

  @override
  List<Object?> get props => [routes];
}

class DriverAssignedRoutesError extends DriverAssignedRoutesState {
  final String message;

  const DriverAssignedRoutesError(this.message);

  @override
  List<Object?> get props => [message];
}
