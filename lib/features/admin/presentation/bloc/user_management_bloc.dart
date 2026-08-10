import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/services/user_management_service.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_state.dart';

/// Compartido por la pantalla de aprobación de choferes y el panel de
/// administración/presidencia — misma lógica, distinto filtro de rol.
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final UserManagementService _service;

  UserManagementBloc({required UserManagementService service})
      : _service = service,
        super(const UserManagementLoading()) {
    on<LoadManagedUsers>(_onLoad);
    on<SetManagedUserActiveState>(_onSetActive);
    on<SetManagedUserQaAccess>(_onSetQaAccess);
  }

  Future<void> _onLoad(
    LoadManagedUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    try {
      final users = await _service.getUsers(userTypeFilter: event.userTypeFilter);
      emit(UserManagementLoaded(users, activeFilter: event.userTypeFilter));
    } catch (e) {
      emit(UserManagementError('No se pudo cargar la lista de usuarios: $e'));
    }
  }

  Future<void> _onSetActive(
    SetManagedUserActiveState event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(UserManagementLoaded(
      current.users,
      activeFilter: current.activeFilter,
      updatingUid: event.uid,
    ));
    try {
      await _service.setUserActive(event.uid, event.isActive);
      final users = await _service.getUsers(userTypeFilter: current.activeFilter);
      emit(UserManagementLoaded(users, activeFilter: current.activeFilter));
    } catch (e) {
      emit(UserManagementError('No se pudo actualizar el estado del usuario: $e'));
    }
  }

  Future<void> _onSetQaAccess(
    SetManagedUserQaAccess event,
    Emitter<UserManagementState> emit,
  ) async {
    final current = state;
    if (current is! UserManagementLoaded) return;
    emit(UserManagementLoaded(
      current.users,
      activeFilter: current.activeFilter,
      updatingUid: event.uid,
    ));
    try {
      await _service.setQaAccess(event.uid, event.qaAccess);
      final users = await _service.getUsers(userTypeFilter: current.activeFilter);
      emit(UserManagementLoaded(users, activeFilter: current.activeFilter));
    } catch (e) {
      emit(UserManagementError('No se pudo actualizar el acceso QA: $e'));
    }
  }
}
