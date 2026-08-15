import 'package:equatable/equatable.dart';

abstract class TickeadorEvent extends Equatable {
  const TickeadorEvent();

  @override
  List<Object?> get props => [];
}

class LoadVerificationHistory extends TickeadorEvent {
  final String tickeadorUid;

  const LoadVerificationHistory(this.tickeadorUid);

  @override
  List<Object?> get props => [tickeadorUid];
}

class ValidateTripQr extends TickeadorEvent {
  final String qrData;
  final String tickeadorUid;

  const ValidateTripQr(this.qrData, this.tickeadorUid);

  @override
  List<Object?> get props => [qrData, tickeadorUid];
}

class ClearLastValidation extends TickeadorEvent {
  const ClearLastValidation();
}
