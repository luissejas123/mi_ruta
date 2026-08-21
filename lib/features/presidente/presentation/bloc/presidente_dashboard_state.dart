import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class PresidenteDashboardState extends Equatable {
  const PresidenteDashboardState();
  @override
  List<Object?> get props => [];
}

class PresidenteDashboardInitial extends PresidenteDashboardState {}

class PresidenteDashboardLoading extends PresidenteDashboardState {}

class PresidenteDashboardLoaded extends PresidenteDashboardState {
  final List<RouteEntity> routes;
  const PresidenteDashboardLoaded(this.routes);
  @override
  List<Object?> get props => [routes];
}

class PresidenteDashboardError extends PresidenteDashboardState {
  final String message;
  const PresidenteDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
