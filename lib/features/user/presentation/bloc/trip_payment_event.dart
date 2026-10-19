
import 'package:equatable/equatable.dart';

abstract class TripPaymentEvent extends Equatable {
  const TripPaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends TripPaymentEvent {
  final String userId;
  final String qrData;

  /// Referencia de la línea abordada.
  /// Si se proporciona, el QR debe corresponder a esa línea.
  final String? expectedRouteRef;

  /// Identificador del viaje de abordaje en curso.
  /// Si se proporciona, el QR debe corresponder a ese viaje.
  final String? expectedTripId;

  const ProcessPaymentEvent({
    required this.userId,
    required this.qrData,
    this.expectedRouteRef,
    this.expectedTripId,
  });

  @override
  List<Object?> get props => [
        userId,
        qrData,
        expectedRouteRef,
        expectedTripId,
      ];
}

/// Cancela un viaje ya pagado y devuelve el saldo al pasajero.
class RefundTripEvent extends TripPaymentEvent {
  final String userId;
  final String tripId;

  const RefundTripEvent({
    required this.userId,
    required this.tripId,
  });

  @override
  List<Object?> get props => [userId, tripId];
}

class ClearPaymentEvent extends TripPaymentEvent {
  const ClearPaymentEvent();
}
