import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/domain/repositories/passenger_report_repository.dart';
import 'package:mi_ruta/features/user/data/repositories/passenger_report_repository_mock.dart';
import 'package:mi_ruta/features/user/presentation/bloc/passenger_report_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/passenger_report_state.dart';

class PassengerReportBLoC extends Bloc<PassengerReportEvent, PassengerReportState> {
  final PassengerReportRepository _repository;

  PassengerReportBLoC({PassengerReportRepository? repository})
      : _repository = repository ??
            PassengerReportRepositoryMock(),
        super(const PassengerReportInitial()) {
    on<LoadPassengerReportEvent>(_onLoadReport);
    on<RefreshPassengerReportEvent>(_onRefresh);
  }

  Future<void> _onLoadReport(
    LoadPassengerReportEvent event,
    Emitter<PassengerReportState> emit,
  ) async {
    emit(const PassengerReportLoading());

    try {
      final result = await _repository.getReport(event.userId, event.period);

      result.fold(
        (failure) => emit(PassengerReportError(failure.message)),
        (report) => emit(PassengerReportLoaded(report)),
      );
    } catch (e) {
      emit(PassengerReportError('Error al cargar el reporte: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshPassengerReportEvent event,
    Emitter<PassengerReportState> emit,
  ) async {
    // Re-lanza el último evento de carga o puede reinicializarse
    if (state is PassengerReportLoaded) {
      emit(PassengerReportInitial());
      // No recarga automática; la pantalla decidirá cuándo disparar LoadPassengerReportEvent
    } else {
      emit(PassengerReportInitial());
    }
  }
}