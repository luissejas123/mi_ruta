import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/presidente/domain/services/presidente_dashboard_service.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_dashboard_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/presidente_dashboard_state.dart';

class PresidenteDashboardBloc
    extends Bloc<PresidenteDashboardEvent, PresidenteDashboardState> {
  final PresidenteDashboardService _service;

  PresidenteDashboardBloc({required PresidenteDashboardService service})
    : _service = service,
      super(PresidenteDashboardInitial()) {
    on<LoadRoutesOverview>(_onLoad);
  }

  Future<void> _onLoad(
    LoadRoutesOverview event,
    Emitter<PresidenteDashboardState> emit,
  ) async {
    emit(PresidenteDashboardLoading());
    try {
      final routes = await _service.getRoutesOverview();
      emit(PresidenteDashboardLoaded(routes));
    } catch (e) {
      emit(PresidenteDashboardError('Error al cargar rutas: $e'));
    }
  }
}
