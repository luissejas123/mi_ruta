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

class ClearPaymentEvent extends TripPaymentEvent {
  const ClearPaymentEvent();
}
