import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_routes_event.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_routes_state.dart';

/// "Paradas cercanas" real: como no hay paradas GTFS sembradas (ver
/// `RouteLocalDatabase.getRoutesNearPoint`), busca qué rutas/trufis pasan
/// dentro del radio elegido, en vez de paradas puntuales.
class NearbyRoutesBloc extends Bloc<NearbyRoutesEvent, NearbyRoutesState> {
  final RouteDataSyncService _syncService;

  NearbyRoutesBloc({required RouteDataSyncService syncService})
      : _syncService = syncService,
        super(NearbyRoutesInitial()) {
    on<LoadNearbyRoutes>(_onLoad);
  }

  Future<void> _onLoad(
    LoadNearbyRoutes event,
    Emitter<NearbyRoutesState> emit,
  ) async {
    emit(NearbyRoutesLoading());
    try {
      final routes = await _syncService.getRoutesWithinRadius(
        latitude: event.lat,
        longitude: event.lng,
        radiusMeters: event.radiusMeters,
      );
      emit(NearbyRoutesLoaded(routes, event.lat, event.lng, event.radiusMeters));
    } catch (e) {
      emit(NearbyRoutesError('Error al buscar rutas cercanas: $e'));
    }
  }
}
