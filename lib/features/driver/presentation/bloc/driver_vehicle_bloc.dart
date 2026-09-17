import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_shift.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/usecases/driver_shift_usecases.dart';
import 'package:mi_ruta/features/driver/domain/usecases/vehicle_usecases.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_vehicle_state.dart';

/// BLoC para gestionar la unidad asignada al chofer.
class DriverVehicleBloc extends Bloc<DriverVehicleEvent, DriverVehicleState> {
  final GetMyVehicleStreamUseCase getMyVehicleStreamUseCase;
  final SetVehicleOnDutyUseCase setVehicleOnDutyUseCase;
  final StartDriverShiftUseCase startDriverShiftUseCase;
  final EndDriverShiftUseCase endDriverShiftUseCase;

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
    required this.startDriverShiftUseCase,
    required this.endDriverShiftUseCase,
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
      final closedShift = await _applyShiftTransition(
        vehicleId: _demoVehicle.vehicleId,
        driverUid: _demoVehicle.ownerUid,
        turningOn: event.value,
      );
      emit(DriverVehicleLoaded(
        vehicle: _demoVehicle,
        lastClosedShift: closedShift,
      ));
      return;
    }

    final currentVehicle =
        state is DriverVehicleLoaded ? (state as DriverVehicleLoaded).vehicle : null;

    final result =
        await setVehicleOnDutyUseCase(event.vehicleId, event.value);
    await result.fold(
      // Mantiene la tarjeta de la unidad visible — solo avisa el error,
      // no reemplaza toda la pantalla (el switch vuelve solo a su valor
      // real porque sigue leyendo `vehicle.isOnDuty`, que no cambió).
      (failure) async => emit(DriverVehicleLoaded(
        vehicle: currentVehicle,
        toggleError: failure.message,
      )),
      (_) async {
        if (currentVehicle != null) {
          final closedShift = await _applyShiftTransition(
            vehicleId: currentVehicle.vehicleId,
            driverUid: currentVehicle.ownerUid,
            turningOn: event.value,
          );
          if (closedShift != null) {
            emit(DriverVehicleLoaded(
              vehicle: currentVehicle,
              lastClosedShift: closedShift,
            ));
          }
        }
        // si turningOn==true, el stream real re-emitirá el estado con la
        // unidad actualizada; no hace falta emitir acá.
      },
    );
  }

  /// RQ-82: arranca o cierra el registro de jornada según corresponda.
  /// Devuelve la jornada recién cerrada (para mostrar el resumen) o null si
  /// lo que pasó fue un arranque.
  Future<DriverShiftEntity?> _applyShiftTransition({
    required String vehicleId,
    required String driverUid,
    required bool turningOn,
  }) async {
    if (turningOn) {
      await startDriverShiftUseCase(vehicleId: vehicleId, driverUid: driverUid);
      return null;
    }
    final result = await endDriverShiftUseCase(vehicleId: vehicleId);
    return result.fold((_) => null, (shift) => shift);
  }
}
