import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_approval_state.dart';

/// Cola de aprobación de choferes, para `presidente` y `admin`.
///
/// Muestra dos grupos a partir de la misma colección `users`:
/// - solicitudes pendientes (`driver_request.status == 'pending'`),
/// - choferes ya aprobados (`role == 'driver'`), para poder bloquearlos.
class DriverApprovalBloc extends Bloc<DriverApprovalEvent, DriverApprovalState> {
  final UserManagementService _service;

  DriverApprovalBloc({required UserManagementService service})
      : _service = service,
        super(const DriverApprovalInitial()) {
    on<LoadDriverApprovalQueue>(_onLoad);
    on<ApproveDriverRequest>(_onApprove);
    on<RejectDriverRequest>(_onReject);
    on<SetDriverActiveState>(_onSetActive);
  }

  Future<void> _onLoad(
    LoadDriverApprovalQueue event,
    Emitter<DriverApprovalState> emit,
  ) async {
    emit(const DriverApprovalLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<DriverApprovalState> emit) async {
    try {
      final pending = await _service.getPendingDriverRequests();
      final drivers = await _service.getUsers(userTypeFilter: 'driver');
      emit(DriverApprovalLoaded(
        pendingRequests: pending,
        // Una cuenta recién aprobada aparece en ambas consultas; se muestra
        // solo como chofer aprobado.
        approvedDrivers: drivers
            .where((d) => !pending.any((p) => p.uid == d.uid))
            .toList(),
      ));
    } catch (e) {
      emit(DriverApprovalError('Error al cargar las solicitudes: $e'));
    }
  }

  Future<void> _onApprove(
    ApproveDriverRequest event,
    Emitter<DriverApprovalState> emit,
  ) async {
    await _mutate(
      emit,
      uid: event.uid,
      action: () => _service.resolveDriverRequest(event.uid, approved: true),
      errorMessage: 'Error al aprobar la solicitud',
    );
  }

  Future<void> _onReject(
    RejectDriverRequest event,
    Emitter<DriverApprovalState> emit,
  ) async {
    await _mutate(
      emit,
      uid: event.uid,
      action: () => _service.resolveDriverRequest(event.uid, approved: false),
      errorMessage: 'Error al rechazar la solicitud',
    );
  }

  Future<void> _onSetActive(
    SetDriverActiveState event,
    Emitter<DriverApprovalState> emit,
  ) async {
    await _mutate(
      emit,
      uid: event.uid,
      action: () => _service.setUserActive(event.uid, event.isActive),
      errorMessage: 'Error al actualizar el estado del chofer',
    );
  }

  /// Marca la fila como "en proceso", ejecuta la escritura y recarga.
  Future<void> _mutate(
    Emitter<DriverApprovalState> emit, {
    required String uid,
    required Future<void> Function() action,
    required String errorMessage,
  }) async {
    final current = state;
    if (current is DriverApprovalLoaded) {
      emit(current.copyWith(updatingUid: uid));
    }
    try {
      await action();
    } catch (e) {
      emit(DriverApprovalError('$errorMessage: $e'));
      return;
    }
    await _load(emit);
  }
}
