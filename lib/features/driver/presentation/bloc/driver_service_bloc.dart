import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';

class DriverServiceBloc extends Bloc<DriverServiceEvent, DriverServiceState> {
  final DriverService _service;

  DriverServiceBloc({required DriverService service})
      : _service = service,
        super(const DriverServiceLoading()) {
    on<LoadAssignedVehicle>(_onLoad);
    on<StartService>(_onStart);
    on<StopService>(_onStop);
  }

  VehicleEntity? _currentVehicle() {
    final s = state;
    if (s is DriverServiceLoaded) return s.vehicle;
    if (s is DriverServiceError) return s.vehicle;
    return null;
  }

  Future<void> _onLoad(
    LoadAssignedVehicle event,
    Emitter<DriverServiceState> emit,
  ) async {
    emit(const DriverServiceLoading());
    try {
      final vehicle = await _service.getAssignedVehicle(event.driverUid);
      emit(vehicle == null
          ? const DriverServiceNoVehicle()
          : DriverServiceLoaded(vehicle));
    } catch (e) {
      emit(DriverServiceError('No se pudo cargar la unidad asignada: $e'));
    }
  }

  Future<void> _onStart(
    StartService event,
    Emitter<DriverServiceState> emit,
  ) async {
    final vehicle = _currentVehicle();
    if (vehicle == null) return;
    emit(DriverServiceLoaded(vehicle, isUpdating: true));
    try {
      final updated = await _service.startService(vehicle);
      emit(DriverServiceLoaded(updated));
    } catch (e) {
      emit(DriverServiceError(
        e.toString().replaceFirst('Exception: ', ''),
        vehicle: vehicle,
      ));
    }
  }

  Future<void> _onStop(
    StopService event,
    Emitter<DriverServiceState> emit,
  ) async {
    final vehicle = _currentVehicle();
    if (vehicle == null) return;
    emit(DriverServiceLoaded(vehicle, isUpdating: true));
    try {
      final updated = await _service.stopService(vehicle);
      emit(DriverServiceLoaded(updated));
    } catch (e) {
      emit(DriverServiceError(
        e.toString().replaceFirst('Exception: ', ''),
        vehicle: vehicle,
      ));
    }
  }
}
