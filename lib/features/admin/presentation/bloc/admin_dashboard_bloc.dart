import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/admin_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_dashboard_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_dashboard_state.dart';

class AdminDashboardBloc extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminService _service;

  AdminDashboardBloc({required AdminService service})
      : _service = service,
        super(const AdminDashboardLoading()) {
    on<LoadActiveVehicles>(_onLoad);
  }

  Future<void> _onLoad(
    LoadActiveVehicles event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final vehicles = await _service.getActiveVehicles();
      emit(AdminDashboardLoaded(vehicles));
    } catch (e) {
      emit(AdminDashboardError('No se pudo cargar las unidades activas: $e'));
    }
  }
}
