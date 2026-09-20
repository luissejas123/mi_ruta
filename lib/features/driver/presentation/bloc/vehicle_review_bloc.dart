import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/vehicle_review_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/vehicle_review_state.dart';

/// Cola de revisión de unidades para `presidente`/`admin` — separada de
/// "Aprobar choferes" (`DriverApprovalBloc`) porque una unidad puede volver
/// a pedir revisión (el dueño la edita) sin que haya una solicitud de
/// chofer de por medio.
class VehicleReviewBloc extends Bloc<VehicleReviewEvent, VehicleReviewState> {
  final DriverService _driverService;
  final UserManagementService _userService;

  VehicleReviewBloc({
    required DriverService driverService,
    required UserManagementService userService,
  })  : _driverService = driverService,
        _userService = userService,
        super(const VehicleReviewInitial()) {
    on<LoadVehicleReviewQueue>(_onLoad);
    on<ApproveVehicle>(_onApprove);
    on<RejectVehicle>(_onReject);
  }

  Future<void> _onLoad(
    LoadVehicleReviewQueue event,
    Emitter<VehicleReviewState> emit,
  ) async {
    emit(const VehicleReviewLoading());
    await _load(emit);
  }

  Future<void> _load(Emitter<VehicleReviewState> emit) async {
    try {
      final vehicles = await _driverService.getVehiclesPendingReview();
      if (vehicles.isEmpty) {
        emit(const VehicleReviewLoaded(pending: []));
        return;
      }
      // Los nombres de dueño no viven en VehicleEntity: se cruzan con la
      // lista de usuarios, igual que hace DriverApprovalBloc con
      // driver_request. Una sola consulta para todas las unidades.
      final users = await _userService.getUsers();
      final byUid = {for (final u in users) u.uid: u};
      final entries = vehicles.map((v) {
        final owner = byUid[v.ownerUid];
        return VehicleReviewEntry(
          vehicle: v,
          ownerName: owner?.fullName.isNotEmpty == true ? owner!.fullName : v.ownerUid,
          ownerEmail: owner?.email ?? '',
        );
      }).toList();
      emit(VehicleReviewLoaded(pending: entries));
    } catch (e) {
      emit(VehicleReviewError('Error al cargar las unidades en revisión: $e'));
    }
  }

  Future<void> _onApprove(
    ApproveVehicle event,
    Emitter<VehicleReviewState> emit,
  ) async {
    await _mutate(
      emit,
      vehicleId: event.vehicleId,
      action: () => _driverService.resolveVehicleReview(event.vehicleId, approved: true),
      errorMessage: 'Error al aprobar la unidad',
    );
  }

  Future<void> _onReject(
    RejectVehicle event,
    Emitter<VehicleReviewState> emit,
  ) async {
    await _mutate(
      emit,
      vehicleId: event.vehicleId,
      action: () => _driverService.resolveVehicleReview(event.vehicleId, approved: false),
      errorMessage: 'Error al rechazar la unidad',
    );
  }

  Future<void> _mutate(
    Emitter<VehicleReviewState> emit, {
    required String vehicleId,
    required Future<void> Function() action,
    required String errorMessage,
  }) async {
    final current = state;
    if (current is VehicleReviewLoaded) {
      emit(current.copyWith(updatingVehicleId: vehicleId));
    }
    try {
      await action();
    } catch (e) {
      emit(VehicleReviewError('$errorMessage: $e'));
      return;
    }
    await _load(emit);
  }
}
