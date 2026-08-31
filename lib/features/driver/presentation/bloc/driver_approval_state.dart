import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/user_entity.dart';

abstract class DriverApprovalState extends Equatable {
  const DriverApprovalState();

  @override
  List<Object?> get props => [];
}

class DriverApprovalInitial extends DriverApprovalState {
  const DriverApprovalInitial();
}

class DriverApprovalLoading extends DriverApprovalState {
  const DriverApprovalLoading();
}

class DriverApprovalLoaded extends DriverApprovalState {
  /// Cuentas con `driver_request.status == 'pending'`.
  final List<UserEntity> pendingRequests;

  /// Cuentas que ya tienen `role == 'driver'`.
  final List<UserEntity> approvedDrivers;

  /// UID con una escritura en curso, para mostrar el spinner en esa fila.
  final String? updatingUid;

  const DriverApprovalLoaded({
    required this.pendingRequests,
    required this.approvedDrivers,
    this.updatingUid,
  });

  DriverApprovalLoaded copyWith({String? updatingUid, bool clearUpdating = false}) {
    return DriverApprovalLoaded(
      pendingRequests: pendingRequests,
      approvedDrivers: approvedDrivers,
      updatingUid: clearUpdating ? null : (updatingUid ?? this.updatingUid),
    );
  }

  bool get isEmpty => pendingRequests.isEmpty && approvedDrivers.isEmpty;

  @override
  List<Object?> get props => [pendingRequests, approvedDrivers, updatingUid];
}

class DriverApprovalError extends DriverApprovalState {
  final String message;

  const DriverApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}
