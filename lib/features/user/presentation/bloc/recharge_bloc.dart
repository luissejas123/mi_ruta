import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/services/recharge_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/recharge_state.dart';

class RechargeBloC extends Bloc<RechargeEvent, RechargeState> {
  final RechargeService _rechargeService;

  RechargeBloC({required RechargeService rechargeService})
    : _rechargeService = rechargeService,
      super(const RechargeInitial()) {
    on<SubmitRechargeEvent>(_onSubmitRecharge);
    on<LoadRechargeHistoryEvent>(_onLoadHistory);
    on<LoadRechargeStatusEvent>(_onLoadStatus);
    on<ClearRechargeEvent>(_onClear);
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

      // Aprobar la recarga automáticamente (en producción sería manual)
      await _rechargeService.approveRecharge(rechargeId, event.userId);

      emit(
        RechargeSubmitted(
          rechargeId: rechargeId,
          amount: event.amount,
          message: 'Recarga procesada exitosamente. Saldo actualizado.',
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
}
