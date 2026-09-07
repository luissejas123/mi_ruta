import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

abstract class DriverOperationsState extends Equatable {
  const DriverOperationsState();

  @override
  List<Object?> get props => [];
}

class DriverOperationsInitial extends DriverOperationsState {
  const DriverOperationsInitial();
}

class DriverOperationsLoading extends DriverOperationsState {
  const DriverOperationsLoading();
}

class DriverOperationsLoaded extends DriverOperationsState {
  final VehicleEntity vehicle;
  final RouteEntity? assignedRoute;
  final List<DriverTripEntity> trips;
  final List<Map<String, dynamic>> incomeTransactions;
  final DriverPerformanceSummary performance;
  final String? activeChargeQr;
  final double? activeChargeAmount;
  final double? lastPaymentReceivedAmount;
  // Trip/pasajero del cobro recibido — llegan directo del doc `trips` vía
  // el stream de TripPaymentReceived, sin consulta aparte. Es lo que permite
  // al Home abrir el flujo "chofer califica al pasajero" apuntando al
  // viaje/usuario correctos (ratings.trip_id/target_uid).
  final String? lastPaymentReceivedTripId;
  final String? lastPaymentReceivedPassengerId;
  final int? lastStopNotifiedCount;
  final bool isBusy;

  const DriverOperationsLoaded({
    required this.vehicle,
    required this.assignedRoute,
    required this.trips,
    required this.incomeTransactions,
    required this.performance,
    this.activeChargeQr,
    this.activeChargeAmount,
    this.lastPaymentReceivedAmount,
    this.lastPaymentReceivedTripId,
    this.lastPaymentReceivedPassengerId,
    this.lastStopNotifiedCount,
    this.isBusy = false,
  });

  DriverOperationsLoaded copyWith({
    VehicleEntity? vehicle,
    RouteEntity? assignedRoute,
    List<DriverTripEntity>? trips,
    List<Map<String, dynamic>>? incomeTransactions,
    DriverPerformanceSummary? performance,
    String? activeChargeQr,
    double? activeChargeAmount,
    bool clearActiveCharge = false,
    double? lastPaymentReceivedAmount,
    String? lastPaymentReceivedTripId,
    String? lastPaymentReceivedPassengerId,
    bool clearLastPayment = false,
    int? lastStopNotifiedCount,
    bool? isBusy,
  }) {
    return DriverOperationsLoaded(
      vehicle: vehicle ?? this.vehicle,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      trips: trips ?? this.trips,
      incomeTransactions: incomeTransactions ?? this.incomeTransactions,
      performance: performance ?? this.performance,
      activeChargeQr: clearActiveCharge ? null : (activeChargeQr ?? this.activeChargeQr),
      activeChargeAmount:
          clearActiveCharge ? null : (activeChargeAmount ?? this.activeChargeAmount),
      lastPaymentReceivedAmount:
          clearLastPayment ? null : (lastPaymentReceivedAmount ?? this.lastPaymentReceivedAmount),
      lastPaymentReceivedTripId:
          clearLastPayment ? null : (lastPaymentReceivedTripId ?? this.lastPaymentReceivedTripId),
      lastPaymentReceivedPassengerId: clearLastPayment
          ? null
          : (lastPaymentReceivedPassengerId ?? this.lastPaymentReceivedPassengerId),
      lastStopNotifiedCount: lastStopNotifiedCount ?? this.lastStopNotifiedCount,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props => [
        vehicle,
        assignedRoute,
        trips,
        incomeTransactions,
        performance,
        activeChargeQr,
        activeChargeAmount,
        lastPaymentReceivedAmount,
        lastPaymentReceivedTripId,
        lastPaymentReceivedPassengerId,
        lastStopNotifiedCount,
        isBusy,
      ];
}

class DriverOperationsError extends DriverOperationsState {
  final String message;

  const DriverOperationsError(this.message);

  @override
  List<Object?> get props => [message];
}
