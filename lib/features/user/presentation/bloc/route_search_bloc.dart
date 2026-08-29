import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/routes/domain/services/route_data_sync_service.dart';
import 'package:mi_ruta/features/routes/domain/services/route_entity_converter.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/route_search_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/route_search_state.dart';

class RouteSearchBloc extends Bloc<RouteSearchEvent, RouteSearchState> {
  final RouteDataSyncService _syncService;

  /// Caché de búsquedas para evitar búsquedas repetidas
  final Map<String, List<RouteMatch>> _cache = {};

  RouteSearchBloc({required RouteDataSyncService syncService})
    : _syncService = syncService,
      super(const RouteSearchInitial()) {
    on<SearchRoutesRequested>(_onSearchRoutesRequested);
    on<SearchCleared>(_onSearchCleared);
  }

  /// Maneja la búsqueda de rutas
  Future<void> _onSearchRoutesRequested(
    SearchRoutesRequested event,
    Emitter<RouteSearchState> emit,
  ) async {
    try {
      emit(const RouteSearchLoading());

      // Generar clave de caché
      final cacheKey = _generateCacheKey(event.origin, event.destination);

      // Verificar caché
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (cached.isEmpty) {
          emit(
            const RouteSearchEmpty(
              message: 'No hay rutas en esa zona. Verifica tu ubicación.',
            ),
          );
        } else {
          emit(RouteSearchSuccess(matches: cached));
        }
        return;
      }

      // Asegurar que los datos locales estén listos (GTFS seed o sync)
      await _syncService.ensureDataReady();

      // Buscar rutas que pasen cerca del ORIGEN y DESTINO
      final nearOriginRows = await _syncService.getRoutesNearPoint(
        latitude: event.origin.latitude,
        longitude: event.origin.longitude,
      );
      final nearDestRows = await _syncService.getRoutesNearPoint(
        latitude: event.destination.latLng.latitude,
        longitude: event.destination.latLng.longitude,
      );

      // Unir sin duplicados por ID
      final allById = <String, dynamic>{};
      for (final r in nearOriginRows) allById[r.id] = r;
      for (final r in nearDestRows) allById.putIfAbsent(r.id, () => r);
      final nearbyRoutes = allById.values.toList();

      if (nearbyRoutes.isEmpty) {
        _cache[cacheKey] = [];
        emit(
          const RouteSearchEmpty(
            message: 'No hay rutas en esa zona. Verifica tu ubicación.',
          ),
        );
        return;
      }

      // Convertir RouteEntity → OsmRoute
      final candidates = <RouteMatch>[];
      for (int i = 0; i < nearbyRoutes.length; i++) {
        final osmRoute = RouteEntityConverter.toOsmRoute(nearbyRoutes[i], i);
        candidates.add(
          RouteMatch(
            route: osmRoute,
            distanceMeters: 0, // Será calculado por findForTrip
          ),
        );
      }

      // Buscar rutas optimas para el viaje
      final matches = RouteFinderService.findForTrip(
        origin: event.origin,
        destination: event.destination.latLng,
        routes: candidates.map((m) => m.route).toList(),
      );

      if (matches.isEmpty) {
        _cache[cacheKey] = [];
        emit(
          const RouteSearchEmpty(
            message: 'No hay rutas que pasen por esa zona',
          ),
        );
        return;
      }

      // Guardar en caché y emitir éxito
      _cache[cacheKey] = matches;
      emit(RouteSearchSuccess(matches: matches));
    } catch (e, st) {
      print('❌ Error buscando rutas: $e\n$st');
      emit(RouteSearchError(message: 'Error: $e'));
    }
  }

  /// Limpia los resultados de búsqueda y caché
  Future<void> _onSearchCleared(
    SearchCleared event,
    Emitter<RouteSearchState> emit,
  ) async {
    _cache.clear();
    emit(const RouteSearchInitial());
  }

  /// Genera una clave única para cachear búsquedas
  String _generateCacheKey(LatLng origin, PlaceResult destination) {
    return '${origin.latitude},${origin.longitude}-'
        '${destination.latLng.latitude},${destination.latLng.longitude}';
  }
}
