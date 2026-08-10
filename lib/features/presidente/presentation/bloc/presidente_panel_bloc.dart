import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_panel_state.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';

/// Sin datasource ni servicio de dominio propios (decisión de arquitectura
/// del plan de Sprint 3): agrega AdminService (usuarios/unidades) y
/// RouteService (catálogo de rutas), ambos ya usados por otras features.
class PresidentePanelBloc extends Bloc<PresidentePanelEvent, PresidentePanelState> {
  final AdminService _adminService;
  final RouteService _routeService;

  PresidentePanelBloc({
    required AdminService adminService,
    required RouteService routeService,
  })  : _adminService = adminService,
        _routeService = routeService,
        super(const PresidentePanelLoading()) {
    on<LoadPresidentePanel>(_onLoad);
  }

  Future<void> _onLoad(
    LoadPresidentePanel event,
    Emitter<PresidentePanelState> emit,
  ) async {
    emit(const PresidentePanelLoading());
    try {
      final routes = await _routeService.getAllActiveRoutes();
      final activeVehicles = await _adminService.getActiveVehicles();
      final allVehicles = await _adminService.getAllVehicles();
      final allUsers = await _adminService.getUsers();
      emit(PresidentePanelLoaded(
        activeRoutes: routes,
        activeVehicles: activeVehicles,
        allVehicles: allVehicles,
        allUsers: allUsers,
      ));
    } catch (e) {
      emit(PresidentePanelError('No se pudo cargar el panel: $e'));
    }
  }
}
