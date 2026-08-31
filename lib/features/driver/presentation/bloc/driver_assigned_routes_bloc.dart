import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_assigned_routes_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_assigned_routes_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_assigned_routes_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

class DriverAssignedRoutesBloc
    extends Bloc<DriverAssignedRoutesEvent, DriverAssignedRoutesState> {
  final DriverAssignedRoutesService _service;

  DriverAssignedRoutesBloc({required DriverAssignedRoutesService service})
    : _service = service,
      super(DriverAssignedRoutesInitial()) {
    on<LoadDriverAssignedRoutes>(_onLoad);
    on<SaveDriverAssignedRoute>(_onSave);
  }

  Future<void> _onLoad(
    LoadDriverAssignedRoutes event,
    Emitter<DriverAssignedRoutesState> emit,
  ) async {
    emit(DriverAssignedRoutesLoading());
    try {
      final routes = await _service.getAssignedRoutes(event.driverId);
      emit(DriverAssignedRoutesLoaded(routes));
    } catch (error) {
      emit(
        DriverAssignedRoutesError(
          'Error al cargar las rutas asignadas: $error',
        ),
      );
    }
  }

  Future<void> _onSave(
    SaveDriverAssignedRoute event,
    Emitter<DriverAssignedRoutesState> emit,
  ) async {
    final currentState = state;
    final routes = currentState is DriverAssignedRoutesLoaded
        ? currentState.routes
        : currentState is DriverAssignedRoutesSaved
        ? currentState.routes
        : currentState is DriverAssignedRoutesSaving
        ? currentState.routes
        : <RouteEntity>[];
    emit(DriverAssignedRoutesSaving(routes));
    try {
      await _service.saveAssignedRoute(
        driverId: event.driverId,
        routeId: event.routeId,
      );
      emit(DriverAssignedRoutesSaved(routes));
    } catch (error) {
      emit(
        DriverAssignedRoutesError('Error al guardar la ruta asignada: $error'),
      );
    }
  }
}
