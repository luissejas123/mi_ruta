import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class DriverApprovalState extends Equatable {
  const DriverApprovalState();

  @override
  List<Object?> get props => [];
}

class DriverApprovalLoading extends DriverApprovalState {
  const DriverApprovalLoading();
}

class DriverApprovalLoaded extends DriverApprovalState {
  final List<UserEntity> drivers;
  final String? updatingUid;

  const DriverApprovalLoaded(this.drivers, {this.updatingUid});

  @override
  List<Object?> get props => [drivers, updatingUid];
}

class DriverApprovalError extends DriverApprovalState {
  final String message;
  const DriverApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}
