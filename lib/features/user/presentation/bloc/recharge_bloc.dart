import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/domain/services/recharge_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_state.dart';

class RechargeBloC extends Bloc<RechargeEvent, RechargeState> {
  final RechargeService _rechargeService;
  final NotificationService _notificationService;

  RechargeBloC({
    required RechargeService rechargeService,
    required NotificationService notificationService,
  })  : _rechargeService = rechargeService,
        _notificationService = notificationService,
        super(const RechargeInitial()) {
    on<SubmitRechargeEvent>(_onSubmitRecharge);
    on<LoadRechargeHistoryEvent>(_onLoadHistory);
    on<LoadRechargeStatusEvent>(_onLoadStatus);
    on<ClearRechargeEvent>(_onClear);
    on<LoadPendingRechargesEvent>(_onLoadPending);
    on<ApproveRechargeEvent>(_onApprove);
    on<RejectRechargeEvent>(_onReject);
  }

  Future<void> _onSubmitRecharge(
    SubmitRechargeEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());

    try {
      // Subir imagen a Firebase Storage y crear recarga
      final rechargeId = await _rechargeService.submitRechargeRequest(
        userId: event.userId,
        amount: event.amount,
        currency: 'Bs',
        proofImageFile: event.proofImageFile,
      );

      // La recarga queda "pending" hasta que el tickeador verifique el
      // comprobante (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 0) — antes
      // se auto-aprobaba acá mismo, acreditando cualquier monto sin revisión.
      emit(
        RechargeSubmitted(
          rechargeId: rechargeId,
          amount: event.amount,
          message: 'Solicitud de recarga enviada. Un tickeador verificará tu comprobante antes de acreditar el saldo.',
        ),
      );
    } catch (e) {
      emit(RechargeError(message: 'Error al procesar recarga: $e'));
    }
  }

  Future<void> _onLoadHistory(
    LoadRechargeHistoryEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());

    try {
      final recharges = await _rechargeService.getRechargeHistory(event.userId);
      emit(RechargeHistoryLoaded(recharges));
    } catch (e) {
      emit(RechargeError(message: 'Error al obtener historial: $e'));
    }
  }

  Future<void> _onLoadStatus(
    LoadRechargeStatusEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());

    try {
      final recharge = await _rechargeService.getRecharge(event.rechargeId);

      if (recharge == null) {
        emit(const RechargeError(message: 'Recarga no encontrada'));
        return;
      }

      emit(RechargeStatusLoaded(recharge));
    } catch (e) {
      emit(RechargeError(message: 'Error al obtener estatus: $e'));
    }
  }

  Future<void> _onClear(
    ClearRechargeEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeInitial());
  }

  Future<void> _onLoadPending(
    LoadPendingRechargesEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());
    try {
      final recharges = await _rechargeService.getAllPendingRecharges();
      emit(PendingRechargesLoaded(recharges));
    } catch (e) {
      emit(RechargeError(message: 'Error al obtener recargas pendientes: $e'));
    }
  }

  Future<void> _onApprove(
    ApproveRechargeEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());
    try {
      await _rechargeService.approveRecharge(event.rechargeId, event.userId);
      await _notificationService.saveRechargeNotification(
        event.userId,
        event.amount,
      );
      final recharges = await _rechargeService.getAllPendingRecharges();
      emit(const RechargeActionSuccess('Recarga aprobada y acreditada.'));
      emit(PendingRechargesLoaded(recharges));
    } catch (e) {
      emit(RechargeError(message: 'Error al aprobar recarga: $e'));
    }
  }

  Future<void> _onReject(
    RejectRechargeEvent event,
    Emitter<RechargeState> emit,
  ) async {
    emit(const RechargeLoading());
    try {
      await _rechargeService.rejectRecharge(event.rechargeId, event.reason);
      await _notificationService.saveRechargeRejectedNotification(
        event.userId,
        event.amount,
      );
      final recharges = await _rechargeService.getAllPendingRecharges();
      emit(const RechargeActionSuccess('Recarga rechazada.'));
      emit(PendingRechargesLoaded(recharges));
    } catch (e) {
      emit(RechargeError(message: 'Error al rechazar recarga: $e'));
    }
  }
}
