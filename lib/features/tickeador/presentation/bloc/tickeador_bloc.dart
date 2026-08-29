import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_event.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_state.dart';

class TickeadorBloc extends Bloc<TickeadorEvent, TickeadorState> {
  final TickeadorService _service;

  TickeadorBloc({required TickeadorService service})
      : _service = service,
        super(const TickeadorLoading()) {
    on<LoadVerificationHistory>(_onLoadHistory);
    on<ValidateTripQr>(_onValidate);
    on<ClearLastValidation>(_onClearLastValidation);
  }

  Future<void> _onLoadHistory(
    LoadVerificationHistory event,
    Emitter<TickeadorState> emit,
  ) async {
    emit(const TickeadorLoading());
    try {
      final history = await _service.getVerificationHistory(event.tickeadorUid);
      emit(TickeadorLoaded(history: history));
    } catch (e) {
      emit(TickeadorError('No se pudo cargar el historial de validaciones: $e'));
    }
  }

  Future<void> _onValidate(
    ValidateTripQr event,
    Emitter<TickeadorState> emit,
  ) async {
    final current = state;
    final baseHistory =
        current is TickeadorLoaded ? current.history : const <DriverTripEntity>[];
    if (current is TickeadorLoaded) {
      emit(current.copyWith(isValidating: true, clearLastResult: true));
    }
    try {
      final trip = await _service.validatePayment(event.qrData, event.tickeadorUid);
      final history = await _service.getVerificationHistory(event.tickeadorUid);
      emit(TickeadorLoaded(history: history, lastValidatedTrip: trip));
    } catch (e) {
      emit(TickeadorLoaded(
        history: baseHistory,
        lastValidationError: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onClearLastValidation(ClearLastValidation event, Emitter<TickeadorState> emit) {
    final current = state;
    if (current is! TickeadorLoaded) return;
    emit(current.copyWith(clearLastResult: true));
  }
}
