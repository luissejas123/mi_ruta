import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_route_usecases.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/route_management_state.dart';

class RouteManagementBloc
    extends Bloc<RouteManagementEvent, RouteManagementState> {
  final GetAdminRoutesUseCase getRoutesUseCase;
  final CreateAdminRouteUseCase createRouteUseCase;
  final UpdateAdminRouteUseCase updateRouteUseCase;
  final DeleteAdminRouteUseCase deleteRouteUseCase;
  final LoadRoutesFromGtfsUseCase loadRoutesFromGtfsUseCase;

  RouteManagementBloc({
    required this.getRoutesUseCase,
    required this.createRouteUseCase,
    required this.updateRouteUseCase,
    required this.deleteRouteUseCase,
    required this.loadRoutesFromGtfsUseCase,
  }) : super(const RouteManagementInitial()) {
    on<LoadAdminRoutesEvent>(_onLoadRoutes);
    on<SearchAdminRoutesEvent>(_onSearch);
    on<CreateAdminRouteEvent>(_onCreateRoute);
    on<UpdateAdminRouteEvent>(_onUpdateRoute);
    on<DeleteAdminRouteEvent>(_onDeleteRoute);
    on<LoadRoutesFromGtfsAdminEvent>(_onLoadFromGtfs);
  }

  Future<void> _onLoadRoutes(
    LoadAdminRoutesEvent event,
    Emitter<RouteManagementState> emit,
  ) async {
    emit(const RouteManagementLoading());
    final result = await getRoutesUseCase.call();
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (routes) {
        final previous = state;
        final query = previous is AdminRoutesLoaded ? previous.query : '';
        emit(AdminRoutesLoaded(routes: routes, query: query));
      },
    );
  }

  void _onSearch(
    SearchAdminRoutesEvent event,
    Emitter<RouteManagementState> emit,
  ) {
    final current = state;
    if (current is AdminRoutesLoaded) {
      emit(AdminRoutesLoaded(routes: current.routes, query: event.query));
    }
  }

  Future<void> _onCreateRoute(
    CreateAdminRouteEvent event,
    Emitter<RouteManagementState> emit,
  ) async {
    emit(const RouteManagementLoading());
    final result = await createRouteUseCase.call(
      name: event.name,
      ref: event.ref,
      color: event.color,
      description: event.description,
    );
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (_) async {
        emit(const RouteManagementSuccess('Ruta creada correctamente'));
        await _reload(emit);
      },
    );
  }

  Future<void> _onUpdateRoute(
    UpdateAdminRouteEvent event,
    Emitter<RouteManagementState> emit,
  ) async {
    emit(const RouteManagementLoading());
    final result = await updateRouteUseCase.call(
      routeId: event.routeId,
      name: event.name,
      ref: event.ref,
      color: event.color,
      description: event.description,
      active: event.active,
    );
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (_) async {
        emit(const RouteManagementSuccess('Ruta actualizada correctamente'));
        await _reload(emit);
      },
    );
  }

  Future<void> _onDeleteRoute(
    DeleteAdminRouteEvent event,
    Emitter<RouteManagementState> emit,
  ) async {
    emit(const RouteManagementLoading());
    final result = await deleteRouteUseCase.call(event.routeId);
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (_) async {
        emit(const RouteManagementSuccess('Ruta eliminada'));
        await _reload(emit);
      },
    );
  }

  Future<void> _onLoadFromGtfs(
    LoadRoutesFromGtfsAdminEvent event,
    Emitter<RouteManagementState> emit,
  ) async {
    emit(const RouteManagementLoading());
    final result = await loadRoutesFromGtfsUseCase.call();
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (count) async {
        emit(RouteManagementSuccess('$count rutas cargadas desde GTFS'));
        await _reload(emit);
      },
    );
  }

  Future<void> _reload(Emitter<RouteManagementState> emit) async {
    final result = await getRoutesUseCase.call();
    result.fold(
      (failure) => emit(RouteManagementError(failure.message)),
      (routes) => emit(AdminRoutesLoaded(routes: routes)),
    );
  }
}
