import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/usecases/vehicle_usecases.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_state.dart';

/// BLoC para gestionar la unidad asignada al chofer.
class DriverVehicleBloc extends Bloc<DriverVehicleEvent, DriverVehicleState> {
  final GetMyVehicleStreamUseCase getMyVehicleStreamUseCase;
  final SetVehicleOnDutyUseCase setVehicleOnDutyUseCase;

  /// TEMPORAL — unidad fija del "Modo prueba", 100% en memoria.
  VehicleEntity _demoVehicle = VehicleEntity(
    vehicleId: kStaticDemoVehicleId,
    ownerUid: kStaticDemoDriverUid,
    vehicleType: 'micro',
    lineNumber: '101',
    internalNumber: '01',
    brand: 'Volkswagen',
    model: 'Crafter',
    color: 'Blanco',
    passengerCapacity: 20,
    status: 'approved',
    legalDocumentation: const {},
    isOnDuty: false,
    updatedAt: DateTime.now(),
  );

  DriverVehicleBloc({
    required this.getMyVehicleStreamUseCase,
    required this.setVehicleOnDutyUseCase,
  }) : super(const DriverVehicleInitial()) {
    on<StartMyVehicleStream>(_onStartMyVehicleStream);
    on<LoadStaticDemoVehicle>(_onLoadStaticDemoVehicle);
    on<ToggleOnDuty>(_onToggleOnDuty);
  }

  void _onLoadStaticDemoVehicle(
    LoadStaticDemoVehicle event,
    Emitter<DriverVehicleState> emit,
  ) {
    emit(DriverVehicleLoaded(vehicle: _demoVehicle));
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
    if (event.vehicleId == kStaticDemoVehicleId) {
      _demoVehicle = VehicleEntity(
        vehicleId: _demoVehicle.vehicleId,
        ownerUid: _demoVehicle.ownerUid,
        vehicleType: _demoVehicle.vehicleType,
        lineNumber: _demoVehicle.lineNumber,
        internalNumber: _demoVehicle.internalNumber,
        brand: _demoVehicle.brand,
        model: _demoVehicle.model,
        color: _demoVehicle.color,
        passengerCapacity: _demoVehicle.passengerCapacity,
        status: _demoVehicle.status,
        legalDocumentation: _demoVehicle.legalDocumentation,
        isOnDuty: event.value,
        isOnDutyUpdatedAt: DateTime.now(),
        updatedAt: _demoVehicle.updatedAt,
      );
      emit(DriverVehicleLoaded(vehicle: _demoVehicle));
      return;
    }

    final result =
        await setVehicleOnDutyUseCase(event.vehicleId, event.value);
    result.fold(
      (failure) => emit(DriverVehicleError(message: failure.message)),
      (_) {}, // el stream activo re-emitirá el estado actualizado
    );
  }
}
