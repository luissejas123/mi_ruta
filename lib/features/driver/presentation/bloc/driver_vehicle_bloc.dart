import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/usecases/vehicle_usecases.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_state.dart';

/// BLoC para gestionar la unidad asignada al chofer.
class DriverVehicleBloc extends Bloc<DriverVehicleEvent, DriverVehicleState> {
  final GetMyVehicleStreamUseCase getMyVehicleStreamUseCase;
  final SetVehicleOnDutyUseCase setVehicleOnDutyUseCase;

  DriverVehicleBloc({
    required this.getMyVehicleStreamUseCase,
    required this.setVehicleOnDutyUseCase,
  }) : super(const DriverVehicleInitial()) {
    on<StartMyVehicleStream>(_onStartMyVehicleStream);
    on<ToggleOnDuty>(_onToggleOnDuty);
  }

  Future<void> _onStartMyVehicleStream(
    StartMyVehicleStream event,
    Emitter<DriverVehicleState> emit,
  ) async {
    emit(const DriverVehicleLoading());
    await emit.forEach(
      getMyVehicleStreamUseCase(event.ownerUid),
      onData: (result) {
        return result.fold(
          (failure) => DriverVehicleError(message: failure.message),
          (vehicle) => DriverVehicleLoaded(vehicle: vehicle),
        );
      },
      onError: (error, stackTrace) {
        return DriverVehicleError(
            message: 'Error en stream de unidad: ${error.toString()}');
      },
    );
  }

  Future<void> _onToggleOnDuty(
    ToggleOnDuty event,
    Emitter<DriverVehicleState> emit,
  ) async {
    final result =
        await setVehicleOnDutyUseCase(event.vehicleId, event.value);
    result.fold(
      (failure) => emit(DriverVehicleError(message: failure.message)),
      (_) {}, // el stream activo re-emitirá el estado actualizado
    );
  }
}
