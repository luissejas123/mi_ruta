import 'package:equatable/equatable.dart';

/// Reporte de auditoría del tickeador: no es dinero que el tickeador haya
/// cobrado (el tickeador solo valida recargas de billetera, ver
/// `RevisionRecargasPage`) — es cuánto se cobró de verdad en las unidades
/// que pasaron por SU ESTACIÓN, para que pueda verificarlo contra lo que vio
/// pasar. El tickeador no filtra por línea/ruta — registra cualquier
/// vehículo que pase, sin verificar su recorrido en el mapa — así que el
/// universo de este reporte es "vehículos con salida/llegada/punto
/// intermedio marcado por este tickeador en el rango" (`station_logs`), no
/// "líneas asignadas". Lee los cobros reales de `trips`.
class TickeadorPaymentsReportEntity extends Equatable {
  final List<String> vehicleIds;
  final DateTime from;
  final DateTime to;
  final double totalAmount;
  final int totalTrips;
  final List<VehiclePaymentsSummary> byVehicle;
  final List<DailyPaymentsSummary> byDay;

  const TickeadorPaymentsReportEntity({
    required this.vehicleIds,
    required this.from,
    required this.to,
    required this.totalAmount,
    required this.totalTrips,
    required this.byVehicle,
    required this.byDay,
  });

  @override
  List<Object?> get props =>
      [vehicleIds, from, to, totalAmount, totalTrips, byVehicle, byDay];
}

class VehiclePaymentsSummary extends Equatable {
  final String vehicleId;
  final String routeName;
  final double amount;
  final int trips;

  const VehiclePaymentsSummary({
    required this.vehicleId,
    required this.routeName,
    required this.amount,
    required this.trips,
  });

  @override
  List<Object?> get props => [vehicleId, routeName, amount, trips];
}

class DailyPaymentsSummary extends Equatable {
  final DateTime day;
  final double amount;
  final int trips;
  final List<PaymentEntry> entries;

  const DailyPaymentsSummary({
    required this.day,
    required this.amount,
    required this.trips,
    required this.entries,
  });

  @override
  List<Object?> get props => [day, amount, trips, entries];
}

/// Un cobro individual (un viaje de un pasajero), sin agrupar con los demás
/// del mismo día — el desglose diario muestra cada uno por separado y solo
/// suma el total al final del día.
class PaymentEntry extends Equatable {
  final String passengerName;
  final String vehicleId;
  final double amount;
  final DateTime paidAt;

  const PaymentEntry({
    required this.passengerName,
    required this.vehicleId,
    required this.amount,
    required this.paidAt,
  });

  @override
  List<Object?> get props => [passengerName, vehicleId, amount, paidAt];
}
