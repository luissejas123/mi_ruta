import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class TransportedPassengersState extends Equatable {
  final List<RouteEntity> routes;
  final bool isLoadingRoutes;
  final String? routesError;

  final bool isSearching;
  final TransportedPassengersReport? report;
  final String? searchError;

  const TransportedPassengersState({
    this.routes = const [],
    this.isLoadingRoutes = false,
    this.routesError,
    this.isSearching = false,
    this.report,
    this.searchError,
  });

  TransportedPassengersState copyWith({
    List<RouteEntity>? routes,
    bool? isLoadingRoutes,
    String? Function()? routesError,
    bool? isSearching,
    TransportedPassengersReport? Function()? report,
    String? Function()? searchError,
  }) {
    return TransportedPassengersState(
      routes: routes ?? this.routes,
      isLoadingRoutes: isLoadingRoutes ?? this.isLoadingRoutes,
      routesError: routesError != null ? routesError() : this.routesError,
      isSearching: isSearching ?? this.isSearching,
      report: report != null ? report() : this.report,
      searchError: searchError != null ? searchError() : this.searchError,
    );
  }

  @override
  List<Object?> get props => [
    routes,
    isLoadingRoutes,
    routesError,
    isSearching,
    report,
    searchError,
  ];
}
