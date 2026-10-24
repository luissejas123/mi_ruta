import 'package:equatable/equatable.dart';

/// Viaje generado por un chofer para cobro al pasajero, corresponde a un
/// documento de la colección `trips` (ver FIRESTORE_COLLECTIONS_GUIDE.md,
/// campos leídos/escritos por TripPaymentService.processPayment).
class DriverTripEntity extends Equatable {
  final String tripId;
  final String driverId;
  final String vehicleId;
  final String routeRef;
  final String routeName;
  final double baseFare;
  final String status; // pending | completed
  final String paymentStatus; // pending | paid
  final String? passengerId;
  final double? paymentAmount;
  final DateTime? createdAt;
  final DateTime? paidAt;
  // Verificación en ruta por un tickeador (RQ-78/79).
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const DriverTripEntity({
    required this.tripId,
    required this.driverId,
    required this.vehicleId,
    required this.routeRef,
    required this.routeName,
    required this.baseFare,
    required this.status,
    required this.paymentStatus,
    this.passengerId,
    this.paymentAmount,
    this.createdAt,
    this.paidAt,
    this.verifiedBy,
    this.verifiedAt,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isVerified => verifiedBy != null;

  @override
  List<Object?> get props => [
        tripId,
        driverId,
        vehicleId,
        routeRef,
        routeName,
        baseFare,
        status,
        paymentStatus,
        passengerId,
        paymentAmount,
        createdAt,
        paidAt,
        verifiedBy,
        verifiedAt,
      ];
}
