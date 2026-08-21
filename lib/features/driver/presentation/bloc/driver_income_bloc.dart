import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_income_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_state.dart';

class DriverIncomeBloc extends Bloc<DriverIncomeEvent, DriverIncomeState> {
  final DriverIncomeService _service;

  DriverIncomeBloc({required DriverIncomeService service})
    : _service = service,
      super(DriverIncomeInitial()) {
    on<LoadDriverIncome>(_onLoad);
  }

  Future<void> _onLoad(
    LoadDriverIncome event,
    Emitter<DriverIncomeState> emit,
  ) async {
    emit(DriverIncomeLoading());
    try {
      final entries = await _service.getIncomeHistory(event.driverId);
      emit(DriverIncomeLoaded(entries, _service.getTotalIncome(entries)));
    } catch (e) {
      emit(DriverIncomeError('Error al cargar historial de ingresos: $e'));
    }
  }
}
