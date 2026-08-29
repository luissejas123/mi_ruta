import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';

abstract class RouteSearchEvent extends Equatable {
  const RouteSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Inicia una búsqueda de rutas
class SearchRoutesRequested extends RouteSearchEvent {
  final LatLng origin;
  final PlaceResult destination;

  const SearchRoutesRequested({
    required this.origin,
    required this.destination,
  });

  @override
  List<Object?> get props => [origin, destination];
}

/// Limpia los resultados de búsqueda
class SearchCleared extends RouteSearchEvent {
  const SearchCleared();
}
