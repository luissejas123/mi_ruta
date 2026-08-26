import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/tickeador_operations_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/tickeador_operations_state.dart';

class TickeadorOperationsBloc
    extends Bloc<TickeadorOperationsEvent, TickeadorOperationsState> {
  final TickeadorOperationsService _service;

  TickeadorOperationsBloc({required TickeadorOperationsService service})
    : _service = service,
      super(TickeadorOperationsInitial()) {
    on<LoadTickeadorOperations>(_onLoad);
    on<RegisterTickeadorOperation>(_onRegister);
  }

  Future<void> _onLoad(
    LoadTickeadorOperations event,
    Emitter<TickeadorOperationsState> emit,
  ) async {
    emit(TickeadorOperationsLoading());
    try {
      final operations = await _service.getOperations(event.tickeadorId);
      emit(TickeadorOperationsLoaded(operations));
    } catch (error) {
      emit(TickeadorOperationsError('Error al cargar el historial: $error'));
    }
  }

  Future<void> _onRegister(
    RegisterTickeadorOperation event,
    Emitter<TickeadorOperationsState> emit,
  ) async {
    emit(TickeadorOperationSaving());
    try {
      await _service.createOperation(
        tickeadorId: event.tickeadorId,
        stationName: event.stationName,
        lineId: event.lineId,
        logType: event.logType,
        vehiclePlate: event.vehiclePlate,
        driverId: event.driverId,
        passengerCount: event.passengerCount,
        maxCapacity: event.maxCapacity,
      );
      emit(TickeadorOperationSaved());
    } catch (error) {
      emit(TickeadorOperationsError('Error al registrar la operación: $error'));
    }
  }
}
