import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class NearbyRoutesState extends Equatable {
  const NearbyRoutesState();
  @override
  List<Object?> get props => [];
}

class NearbyRoutesInitial extends NearbyRoutesState {}

class NearbyRoutesLoading extends NearbyRoutesState {}

class NearbyRoutesLoaded extends NearbyRoutesState {
  /// Rutas cercanas con su distancia en metros al punto de origen,
  /// ordenadas de más cerca a más lejos.
  final List<(RouteEntity, double)> routes;
  final double originLat;
  final double originLng;
  final double radiusMeters;

  const NearbyRoutesLoaded(
    this.routes,
    this.originLat,
    this.originLng,
    this.radiusMeters,
  );

  @override
  List<Object?> get props => [routes, originLat, originLng, radiusMeters];
}

class NearbyRoutesError extends NearbyRoutesState {
  final String message;
  const NearbyRoutesError(this.message);
  @override
  List<Object?> get props => [message];
}
