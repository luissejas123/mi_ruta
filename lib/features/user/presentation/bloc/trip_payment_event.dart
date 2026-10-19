import 'package:equatable/equatable.dart';

abstract class TripPaymentEvent extends Equatable {
  const TripPaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPaymentEvent extends TripPaymentEvent {
  final String userId;
  final String qrData;

  const ProcessPaymentEvent({required this.userId, required this.qrData});

  @override
  List<Object?> get props => [userId, qrData];
}

/// Cancela un viaje ya pagado y devuelve el saldo al pasajero.
class RefundTripEvent extends TripPaymentEvent {
  final String userId;
  final String tripId;

  const RefundTripEvent({required this.userId, required this.tripId});

  @override
  List<Object?> get props => [userId, tripId];
}

class ClearPaymentEvent extends TripPaymentEvent {
  const ClearPaymentEvent();
}
