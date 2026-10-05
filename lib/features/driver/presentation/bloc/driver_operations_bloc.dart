import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';

class DriverOperationsBloc extends Bloc<DriverOperationsEvent, DriverOperationsState> {
  final DriverService _service;
  StreamSubscription? _tripSubscription;
  // Escucha persistente de pagos mientras el chofer está en servicio — a
  // diferencia de `_tripSubscription` (un solo viaje puntual, cobro
  // inmediato por QR), esta cubre los viajes de abordaje (QR fijo de unidad,
  // aviso de bajada, cobro automático) que antes solo se veían al volver a
  // entrar a una pantalla de chofer (`LoadDriverOperations` es un fetch
  // único, no un stream). `_lastSeenPaidTripId` evita doble aviso cuando
  // ambos streams detectan el mismo viaje.
  StreamSubscription<DriverTripEntity?>? _paidTripsSubscription;
  String? _lastSeenPaidTripId;
  bool _paidTripsBaselineSet = false;
  StreamSubscription<int>? _boardedCountSubscription;

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
    on<BoardedCountUpdated>(_onBoardedCountUpdated);
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    _paidTripsSubscription?.cancel();
    _boardedCountSubscription?.cancel();
    return super.close();
  }

  void _ensureBoardedCountListener(String vehicleId) {
    if (_boardedCountSubscription != null) return;
    _boardedCountSubscription = _service.streamBoardedCount(vehicleId).listen(
          (count) => add(BoardedCountUpdated(count)),
          // Sin esto, un error del stream (ej. falta de índice) lo mataba en
          // silencio y el contador se quedaba pegado en 0 para siempre, sin
          // ningún rastro en consola para diagnosticarlo.
          onError: (e) => print('Error en streamBoardedCount: $e'),
        );
  }

  void _onBoardedCountUpdated(BoardedCountUpdated event, Emitter<DriverOperationsState> emit) {
    final current = state;
    if (current is! DriverOperationsLoaded) return;
    emit(current.copyWith(boardedCount: event.count));
  }

  /// Arranca (una sola vez por chofer) el stream de "último viaje cobrado"
  /// para que los pagos de abordaje avisen al chofer en vivo, no solo al
  /// volver a abrir una pantalla de chofer.
  void _ensurePaidTripsListener(String driverId) {
    if (_paidTripsSubscription != null) return;
    _paidTripsBaselineSet = false;
    _paidTripsSubscription = _service.streamLatestPaidTrip(driverId).listen((trip) {
      if (trip == null) return;
      // El primer snapshot es la foto actual (puede incluir viajes ya
      // cobrados antes de abrir la app) — no se avisa por esos, solo por
      // los que lleguen DESPUÉS de esa foto inicial.
      if (!_paidTripsBaselineSet) {
        _paidTripsBaselineSet = true;
        _lastSeenPaidTripId = trip.tripId;
        return;
      }
      if (trip.tripId == _lastSeenPaidTripId) return;
      _lastSeenPaidTripId = trip.tripId;
      add(TripPaymentReceived(
        trip.tripId,
        trip.paymentAmount ?? trip.baseFare,
        passengerId: trip.passengerId,
      ));
    }, onError: (e) => print('Error en streamLatestPaidTrip: $e'));
  }

  Future<void> _onLoad(
    LoadDriverOperations event,
    Emitter<DriverOperationsState> emit,
  ) async {
    final previousBoardedCount = state is DriverOperationsLoaded
        ? (state as DriverOperationsLoaded).boardedCount
        : 0;
    emit(const DriverOperationsLoading());
    _ensurePaidTripsListener(event.vehicle.ownerUid);
    _ensureBoardedCountListener(event.vehicle.vehicleId);
    // Respaldo de "tarifa máxima si nadie avisó que bajó" (Bloque 2, paso 3)
    // — no bloquea la carga si falla o tarda.
    unawaited(_service.chargeStaleBoardingTrips(event.vehicle.ownerUid));
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
        // Si ya había un estado cargado antes de este reload (lo dispara
        // `_onTripPaymentReceived` tras un pago), se mantiene el
        // `boardedCount` que ya tenía el stream en vivo — si no, volvía a
        // 0 hasta el próximo snapshot de `streamBoardedCount`.
        boardedCount: previousBoardedCount,
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
          add(TripPaymentReceived(
            charge['tripId'],
            charge['amount'] as double,
            passengerId: statusMap['passenger_id'] as String?,
          ));
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
    // El stream de cobro inmediato puede reportar este mismo viaje antes de
    // que `_paidTripsSubscription` lo vea — se marca ya visto para que no
    // avise dos veces por el mismo pago.
    _lastSeenPaidTripId = event.tripId;
    final current = state;
    if (current is! DriverOperationsLoaded) return;

    // Oculta el QR y guarda el monto (y el viaje/pasajero) para mostrar el
    // snackbar y, si corresponde, abrir "calificar al pasajero".
    emit(current.copyWith(
      clearActiveCharge: true,
      lastPaymentReceivedAmount: event.amount,
      lastPaymentReceivedTripId: event.tripId,
      lastPaymentReceivedPassengerId: event.passengerId,
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
      final count = await _service.notifyStop(current.vehicle);
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
