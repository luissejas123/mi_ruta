import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';

abstract class DriverRequestState extends Equatable {
  const DriverRequestState();

  @override
  List<Object?> get props => [];
}

class DriverRequestIdle extends DriverRequestState {
  const DriverRequestIdle();
}

class DriverRequestSending extends DriverRequestState {
  const DriverRequestSending();
}

class DriverRequestSent extends DriverRequestState {
  const DriverRequestSent();
}

class DriverRequestFailed extends DriverRequestState {
  final String message;

  const DriverRequestFailed(this.message);

  @override
  List<Object?> get props => [message];
}

/// Envía la solicitud del propio usuario para ser chofer.
///
/// No cambia el `role`: solo escribe `driver_request.status = 'pending'`. La
/// pantalla no necesita recargar — `users/{uid}` está siendo escuchado por
/// `UserBloc`, así que el perfil se actualiza solo al confirmarse la escritura.
class DriverRequestCubit extends Cubit<DriverRequestState> {
  final UserManagementService _service;

  DriverRequestCubit({required UserManagementService service})
      : _service = service,
        super(const DriverRequestIdle());

  Future<void> requestDriverRole(String uid) async {
    emit(const DriverRequestSending());
    try {
      await _service.requestDriverRole(uid);
      emit(const DriverRequestSent());
    } catch (e) {
      emit(DriverRequestFailed('No se pudo enviar la solicitud: $e'));
    }
  }
}
