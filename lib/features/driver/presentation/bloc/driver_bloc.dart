import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/usecases/activate_driver_mode_usecase.dart';
import 'package:mi_ruta/features/driver/domain/usecases/deactivate_driver_mode_usecase.dart';
import 'package:mi_ruta/features/driver/domain/usecases/get_my_vehicle_application_usecase.dart';
import 'package:mi_ruta/features/driver/domain/usecases/submit_vehicle_application_usecase.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final GetMyVehicleApplicationUseCase getMyVehicleApplicationUseCase;
  final SubmitVehicleApplicationUseCase submitVehicleApplicationUseCase;
  final ActivateDriverModeUseCase activateDriverModeUseCase;
  final DeactivateDriverModeUseCase deactivateDriverModeUseCase;

  DriverBloc({
    required this.getMyVehicleApplicationUseCase,
    required this.submitVehicleApplicationUseCase,
    required this.activateDriverModeUseCase,
    required this.deactivateDriverModeUseCase,
  }) : super(DriverInitial()) {
    on<LoadMyVehicleApplication>(_onLoad);
    on<SubmitVehicleApplication>(_onSubmit);
    on<ActivateDriverMode>(_onActivate);
    on<DeactivateDriverMode>(_onDeactivate);
  }

  Future<void> _onLoad(
    LoadMyVehicleApplication event,
    Emitter<DriverState> emit,
  ) async {
    emit(DriverLoading());
    final result = await getMyVehicleApplicationUseCase(event.userId);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (vehicle) => emit(
        vehicle == null
            ? NoVehicleApplication()
            : VehicleApplicationLoaded(vehicle),
      ),
    );
  }

  Future<void> _onSubmit(
    SubmitVehicleApplication event,
    Emitter<DriverState> emit,
  ) async {
    emit(DriverLoading());
    final result = await submitVehicleApplicationUseCase(
      userId: event.userId,
      plate: event.plate,
      vehicleType: event.vehicleType,
      lineNumber: event.lineNumber,
      internalNumber: event.internalNumber,
      brand: event.brand,
      model: event.model,
      color: event.color,
      passengerCapacity: event.passengerCapacity,
      soatFile: event.soatFile,
      vehicleInspectionFile: event.vehicleInspectionFile,
      driverLicenseFile: event.driverLicenseFile,
      municipalOperationCardFile: event.municipalOperationCardFile,
      ruatFile: event.ruatFile,
    );
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (vehicle) => emit(VehicleApplicationLoaded(vehicle)),
    );
  }

  Future<void> _onActivate(
    ActivateDriverMode event,
    Emitter<DriverState> emit,
  ) async {
    emit(DriverLoading());
    final result = await activateDriverModeUseCase(event.userId);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (_) => emit(DriverModeActivated()),
    );
  }

  Future<void> _onDeactivate(
    DeactivateDriverMode event,
    Emitter<DriverState> emit,
  ) async {
    emit(DriverLoading());
    final result = await deactivateDriverModeUseCase(event.userId);
    result.fold(
      (failure) => emit(DriverError(failure.message)),
      (_) => emit(DriverModeDeactivated()),
    );
  }
}
