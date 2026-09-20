import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/routes/domain/services/planned_trip_service.dart';
import 'package:mi_ruta/features/routes/presentation/bloc/trip_planner_event.dart';
import 'package:mi_ruta/features/routes/presentation/bloc/trip_planner_state.dart';

class TripPlannerBloc extends Bloc<TripPlannerEvent, TripPlannerState> {
  final PlannedTripService _service;

  TripPlannerBloc({required PlannedTripService service})
    : _service = service,
      super(TripPlannerInitial()) {
    on<SearchTripOptions>(_onSearch);
    on<SaveTripPlan>(_onSave);
    on<LoadMyPlans>(_onLoadMyPlans);
    on<DeleteTripPlan>(_onDelete);
    on<MarkTripCompleted>(_onMarkCompleted);
    on<LoadCancelledTrips>(_onLoadCancelledTrips);
    on<ClearSearch>((_, emit) => emit(TripPlannerInitial()));
  }

  Future<void> _onSearch(
    SearchTripOptions event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(TripPlannerLoading());
    try {
      final options = await _service.searchOptions(
        userId: event.userId,
        origin: event.origin,
        destination: event.destination,
        originName: event.originName,
        destinationName: event.destinationName,
        scheduledAt: event.scheduledAt,
      );
      if (options.isEmpty) {
        emit(TripSearchEmpty());
      } else {
        emit(TripSearchResults(options));
      }
    } catch (e) {
      emit(TripPlannerError('Error buscando rutas: $e'));
    }
  }

  Future<void> _onSave(
    SaveTripPlan event,
    Emitter<TripPlannerState> emit,
  ) async {
    try {
      await _service.save(event.trip);
      emit(TripPlanSaved(event.trip));
    } catch (e) {
      emit(TripPlannerError('Error guardando plan: $e'));
    }
  }

  Future<void> _onLoadMyPlans(
    LoadMyPlans event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(TripPlannerLoading());
    try {
      final plans = await _service.getMyPlans(event.userId);
      emit(MyPlansLoaded(plans));
    } catch (e) {
      emit(TripPlannerError('Error cargando planes: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteTripPlan event,
    Emitter<TripPlannerState> emit,
  ) async {
    await _service.delete(event.userId, event.tripId);
    add(LoadMyPlans(event.userId));
  }

  Future<void> _onMarkCompleted(
    MarkTripCompleted event,
    Emitter<TripPlannerState> emit,
  ) async {
    await _service.markCompleted(event.userId, event.tripId);
    add(LoadMyPlans(event.userId));
  }

  Future<void> _onLoadCancelledTrips(
    LoadCancelledTrips event,
    Emitter<TripPlannerState> emit,
  ) async {
    emit(TripPlannerLoading());
    try {
      final trips = await _service.getCancelledTrips(event.userId);
      emit(CancelledTripsLoaded(trips));
    } catch (e) {
      emit(TripPlannerError('Error cargando viajes cancelados: $e'));
    }
  }
}
