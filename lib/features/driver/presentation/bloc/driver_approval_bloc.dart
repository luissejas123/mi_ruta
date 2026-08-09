import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_state.dart';

class DriverApprovalBloc extends Bloc<DriverApprovalEvent, DriverApprovalState> {
  final DriverService _service;

  DriverApprovalBloc({required DriverService service})
      : _service = service,
        super(const DriverApprovalLoading()) {
    on<LoadDriverUsers>(_onLoad);
    on<SetDriverActiveState>(_onSetActive);
  }

  Future<void> _onLoad(
    LoadDriverUsers event,
    Emitter<DriverApprovalState> emit,
  ) async {
    emit(const DriverApprovalLoading());
    try {
      final drivers = await _service.getDriverUsers();
      emit(DriverApprovalLoaded(drivers));
    } catch (e) {
      emit(DriverApprovalError('No se pudo cargar la lista de choferes: $e'));
    }
  }

  Future<void> _onSetActive(
    SetDriverActiveState event,
    Emitter<DriverApprovalState> emit,
  ) async {
    final current = state;
    if (current is! DriverApprovalLoaded) return;
    emit(DriverApprovalLoaded(current.drivers, updatingUid: event.uid));
    try {
      await _service.setDriverActive(event.uid, event.isActive);
      final drivers = await _service.getDriverUsers();
      emit(DriverApprovalLoaded(drivers));
    } catch (e) {
      emit(DriverApprovalError('No se pudo actualizar el estado del chofer: $e'));
    }
  }
}
