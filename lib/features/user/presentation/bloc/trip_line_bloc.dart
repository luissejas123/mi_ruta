import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/features/user/data/datasources/walking_routes_datasource.dart';
import 'package:mi_ruta/features/user/domain/services/trip_segment_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_line_state.dart';

class TripLineBloc extends Bloc<TripLineEvent, TripLineState> {
  final WalkingRoutesDatasource _walkingDatasource;

  TripLineBloc({WalkingRoutesDatasource? walkingDatasource})
    : _walkingDatasource = walkingDatasource ?? WalkingRoutesDatasource(),
      super(const TripLineInitial()) {
    on<TripLineInitialized>(_onTripLineInitialized);
  }

  Future<void> _onTripLineInitialized(
    TripLineInitialized event,
    Emitter<TripLineState> emit,
  ) async {
    try {
      emit(const TripLineLoading());

      // Calcular segmento de viaje (boarding/alighting stops)
      final origin = event.origin ?? event.destination.latLng;
      final segment = TripSegmentService.compute(
        route: event.route,
        origin: origin,
        destination: event.destination.latLng,
      );

      // Cargar rutas de caminata
      final futures = <Future<List<LatLng>>>[];

      // Ruta de caminata inicial (si existe origen)
      if (event.origin != null) {
        futures.add(
          _walkingDatasource.fetchRoute(event.origin!, segment.boardingStop),
        );
      }

      // Ruta de caminata final
      futures.add(
        _walkingDatasource.fetchRoute(
          segment.alightingStop,
          event.destination.latLng,
        ),
      );

      final results = await Future.wait(futures);

      // Construir walking paths según si había origen o no
      final walkingPaths = WalkingPaths(
        startWalkPath: event.origin != null ? results[0] : [],
        endWalkPath: event.origin != null ? results[1] : results[0],
      );

      emit(
        TripLineLoaded(
          tripSegment: TripSegmentData(
            boardingStop: segment.boardingStop,
            alightingStop: segment.alightingStop,
            transitPoints: segment.transitPoints,
          ),
          walkingPaths: walkingPaths,
        ),
      );
    } catch (e, st) {
      print('❌ Error initializing trip line: $e\n$st');
      emit(TripLineError(message: 'Error: $e'));
    }
  }
}
