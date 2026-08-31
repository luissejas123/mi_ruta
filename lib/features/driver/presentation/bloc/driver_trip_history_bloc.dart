import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_state.dart';

class DriverTripHistoryBloc
    extends Bloc<DriverTripHistoryEvent, DriverTripHistoryState> {
  final DriverService driverService;

  DriverTripHistoryBloc({required this.driverService})
      : super(const TripHistoryInitial()) {
    on<LoadTripHistory>(_onLoadTripHistory);
  }

  void _onLoadTripHistory(
    LoadTripHistory event,
    Emitter<DriverTripHistoryState> emit,
  ) async {
    try {
      emit(const TripHistoryLoading());
      
      final trips = await driverService.getDriverTrips(event.driverId);
      
      emit(TripHistoryLoaded(trips: trips));
    } catch (e) {
      emit(TripHistoryError(e.toString()));
    }
  }
}