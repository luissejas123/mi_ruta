import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/stops/domain/services/bus_stop_service.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_stops_event.dart';
import 'package:mi_ruta/features/stops/presentation/bloc/nearby_stops_state.dart';

class NearbyStopsBloc extends Bloc<NearbyStopsEvent, NearbyStopsState> {
  final BusStopService _service;

  NearbyStopsBloc({required BusStopService service})
    : _service = service,
      super(NearbyStopsInitial()) {
    on<LoadNearbyStops>(_onLoad);
  }

  Future<void> _onLoad(
    LoadNearbyStops event,
    Emitter<NearbyStopsState> emit,
  ) async {
    emit(NearbyStopsLoading());
    try {
      final stops = await _service.getNearbyStops(
        event.lat,
        event.lng,
        radiusMeters: event.radiusMeters,
      );
      emit(NearbyStopsLoaded(stops, event.lat, event.lng));
    } catch (e) {
      emit(NearbyStopsError('Error al cargar paradas: $e'));
    }
  }
}
