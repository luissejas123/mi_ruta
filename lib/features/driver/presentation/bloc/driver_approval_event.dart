import 'package:equatable/equatable.dart';

abstract class DriverApprovalEvent extends Equatable {
  const DriverApprovalEvent();

  @override
  List<Object?> get props => [];
}

/// Carga la cola: solicitudes pendientes + choferes ya aprobados.
class LoadDriverApprovalQueue extends DriverApprovalEvent {
  const LoadDriverApprovalQueue();
}

/// Aprueba la solicitud y promueve la cuenta a `driver`.
class ApproveDriverRequest extends DriverApprovalEvent {
  final String uid;

  const ApproveDriverRequest(this.uid);

  @override
  List<Object?> get props => [uid];
}

class RejectDriverRequest extends DriverApprovalEvent {
  final String uid;

  const RejectDriverRequest(this.uid);

  @override
  List<Object?> get props => [uid];
}

/// Bloquea/desbloquea un chofer ya aprobado (`isActive`).
class SetDriverActiveState extends DriverApprovalEvent {
  final String uid;
  final bool isActive;

  const SetDriverActiveState(this.uid, this.isActive);

  @override
  List<Object?> get props => [uid, isActive];
}
