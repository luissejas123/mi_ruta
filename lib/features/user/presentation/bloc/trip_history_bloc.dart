import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_history_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_history_state.dart';

class TripHistoryBloc extends Bloc<TripHistoryEvent, TripHistoryState> {
  final TripHistoryService _service;

  TripHistoryBloc({required TripHistoryService service})
      : _service = service,
        super(TripHistoryInitial()) {
    on<LoadTripHistory>(_onLoad);
  }

  Future<void> _onLoad(
    LoadTripHistory event,
    Emitter<TripHistoryState> emit,
  ) async {
    emit(TripHistoryLoading());
    try {
      final trips = await _service.getTrips(event.userId);
      emit(TripHistoryLoaded(trips));
    } catch (e) {
      emit(TripHistoryError('Error al cargar historial: $e'));
    }
  }
}
