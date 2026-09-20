import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class RouteManagementState extends Equatable {
  const RouteManagementState();

  @override
  List<Object?> get props => [];
}

class RouteManagementInitial extends RouteManagementState {
  const RouteManagementInitial();
}

class RouteManagementLoading extends RouteManagementState {
  const RouteManagementLoading();
}

class AdminRoutesLoaded extends RouteManagementState {
  final List<RouteEntity> routes;
  final String query;

  const AdminRoutesLoaded({required this.routes, this.query = ''});

  /// Filtro local por nombre, ref o ID.
  List<RouteEntity> get filteredRoutes {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return routes;
    return routes
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.ref.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q))
        .toList();
  }

  @override
  List<Object?> get props => [routes, query];
}

/// Estado transitorio para mostrar SnackBar de éxito.
class RouteManagementSuccess extends RouteManagementState {
  final String message;

  const RouteManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class RouteManagementError extends RouteManagementState {
  final String message;

  const RouteManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
