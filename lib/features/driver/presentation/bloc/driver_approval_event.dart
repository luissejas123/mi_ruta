import 'package:equatable/equatable.dart';

abstract class DriverApprovalEvent extends Equatable {
  const DriverApprovalEvent();

  @override
  List<Object?> get props => [];
}

class LoadDriverUsers extends DriverApprovalEvent {
  const LoadDriverUsers();
}

class SetDriverActiveState extends DriverApprovalEvent {
  final String uid;
  final bool isActive;

  const SetDriverActiveState(this.uid, this.isActive);

  @override
  List<Object?> get props => [uid, isActive];
}
