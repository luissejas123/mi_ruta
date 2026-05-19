import 'package:equatable/equatable.dart';

abstract class TripPaymentState extends Equatable {
  const TripPaymentState();

  @override
  List<Object?> get props => [];
}

class TripPaymentInitial extends TripPaymentState {
  const TripPaymentInitial();
}

class TripPaymentLoading extends TripPaymentState {
  const TripPaymentLoading();
}

class TripPaymentSuccess extends TripPaymentState {
  final String message;
  final double amount;
  final double newBalance;
  final String tripId;

  const TripPaymentSuccess({
    required this.message,
    required this.amount,
    required this.newBalance,
    required this.tripId,
  });

  @override
  List<Object?> get props => [message, amount, newBalance, tripId];
}

class TripPaymentError extends TripPaymentState {
  final String message;

  const TripPaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}
