import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';

class DriverOperationsBloc extends Bloc<DriverOperationsEvent, DriverOperationsState> {
  final DriverService _service;
  StreamSubscription? _tripSubscription;

  DriverOperationsBloc({required DriverService service})
      : _service = service,
        super(const DriverOperationsInitial()) {
    on<LoadDriverOperations>(_onLoad);
    on<GenerateTripCharge>(_onGenerateCharge);
    on<ClearTripCharge>(_onClearCharge);
    on<UpdateVehicleInfo>(_onUpdateVehicleInfo);
    on<DownloadTripHistory>(_onDownloadHistory);
    on<NotifyStop>(_onNotifyStop);
    on<TripPaymentReceived>(_onTripPaymentReceived);
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadDriverOperations event,
    Emitter<DriverOperationsState> emit,
  ) async {
    emit(const DriverOperationsLoading());
    try {
      final route = await _service.getAssignedRoute(event.vehicle);
      
      List<DriverTripEntity> trips = [];
      try {
        trips = await _service.getTripHistory(event.vehicle.ownerUid);
      } catch (e) {
        print('Error cargando historial de viajes: $e');
      }

      List<Map<String, dynamic>> income = [];
      try {
        income = await _service.getIncomeTransactions(event.vehicle.ownerUid);
      } catch (e) {
        print('Error cargando ingresos: $e');
      }

      emit(DriverOperationsLoaded(
        vehicle: event.vehicle,
        assignedRoute: route,
        trips: trips,
        incomeTransactions: income,
        performance: _service.buildPerformanceSummary(trips),
      ));
    } catch (e) {
      emit(DriverOperationsError('No se pudo cargar la información del vehículo o ruta: $e'));
    }
  }

  Future<void> _onGenerateCharge(
    GenerateTripCharge event,
    Emitter<DriverOperationsState> emit,
  ) async {
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(isBusy: true));
    try {
      final charge = await _service.generateTripCharge(
        vehicle: current.vehicle,
        amount: event.amount,
        route: current.assignedRoute,
      );
      emit(current.copyWith(
        activeChargeQr: charge['qrData'] as String,
        activeChargeAmount: charge['amount'] as double,
        isBusy: false,
      ));

      _tripSubscription?.cancel();
      _tripSubscription = _service.streamTripStatus(charge['tripId']).listen((statusMap) {
        if (statusMap != null && statusMap['payment_status'] == 'paid') {
          add(TripPaymentReceived(charge['tripId'], charge['amount'] as double));
        }
      });
    } catch (e) {
      emit(DriverOperationsError('No se pudo generar el cobro: $e'));
    }
  }

  void _onClearCharge(ClearTripCharge event, Emitter<DriverOperationsState> emit) {
    _tripSubscription?.cancel();
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(clearActiveCharge: true));
  }

  void _onTripPaymentReceived(TripPaymentReceived event, Emitter<DriverOperationsState> emit) {
    _tripSubscription?.cancel();
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    
    // Oculta el QR y guarda el monto para mostrar el snackbar
    emit(current.copyWith(
      clearActiveCharge: true,
      lastPaymentReceivedAmount: event.amount,
    ));
    
    // Recarga la data del chofer para actualizar ingresos e historial
    add(LoadDriverOperations(current.vehicle));
  }

  Future<void> _onUpdateVehicleInfo(
    UpdateVehicleInfo event,
    Emitter<DriverOperationsState> emit,
  ) async {
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(isBusy: true));
    try {
      await _service.updateVehicleInfo(
        vehicleId: current.vehicle.vehicleId,
        brand: event.brand,
        model: event.model,
        color: event.color,
        internalNumber: event.internalNumber,
      );
      final updatedVehicle = current.vehicle.copyWith(
        brand: event.brand,
        model: event.model,
        color: event.color,
        internalNumber: event.internalNumber,
      );
      emit(current.copyWith(vehicle: updatedVehicle, isBusy: false));
    } catch (e) {
      emit(DriverOperationsError('No se pudo actualizar la unidad: $e'));
    }
  }

  Future<void> _onNotifyStop(
    NotifyStop event,
    Emitter<DriverOperationsState> emit,
  ) async {
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(isBusy: true));
    try {
      final count = await _service.notifyStop(current.vehicle, event.stopName);
      emit(current.copyWith(lastStopNotifiedCount: count, isBusy: false));
    } catch (e) {
      emit(DriverOperationsError('No se pudo enviar el aviso: $e'));
    }
  }

  Future<void> _onDownloadHistory(
    DownloadTripHistory event,
    Emitter<DriverOperationsState> emit,
  ) async {
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(isBusy: true));
    try {
      final file = await _service.exportHistoryPdf(
        driverName: event.driverName,
        trips: current.trips,
        income: current.incomeTransactions,
      );
      await _service.shareFile(file, subject: 'Historial de viajes - Mi Ruta');
      emit(current.copyWith(isBusy: false));
    } catch (e) {
      emit(DriverOperationsError('No se pudo generar el historial: $e'));
    }
  }
}
