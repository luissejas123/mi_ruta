import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_usecases.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final GetAdminUsersUseCase getUsersUseCase;
  final UpdateUserRoleUseCase updateUserRoleUseCase;

  UserManagementBloc({
    required this.getUsersUseCase,
    required this.updateUserRoleUseCase,
  }) : super(const UserManagementInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<SearchUsersEvent>(_onSearch);
    on<PromoteUserToAdminEvent>(_onPromoteUser);
    on<PromoteUserToPresidenteEvent>(_onPromoteUserToPresidente);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    final result = await getUsersUseCase.call();
    result.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (users) {
        final previous = state;
        final query = previous is UserManagementLoaded ? previous.query : '';
        emit(UserManagementLoaded(users: users, query: query));
      },
    );
  }

  void _onSearch(SearchUsersEvent event, Emitter<UserManagementState> emit) {
    final state = this.state;
    if (state is UserManagementLoaded) {
      emit(UserManagementLoaded(users: state.users, query: event.query));
    }
  }

  Future<void> _onPromoteUser(
    PromoteUserToAdminEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    await _promote(
      emit,
      uid: event.uid,
      role: 'admin',
      successMessage: 'Usuario promovido a administrador',
    );
  }

  Future<void> _onPromoteUserToPresidente(
    PromoteUserToPresidenteEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    await _promote(
      emit,
      uid: event.uid,
      role: 'presidente',
      successMessage: 'Usuario promovido a presidente',
    );
  }

  /// Cambia el rol de una cuenta y recarga la lista. Compartido por todas las
  /// promociones: solo cambian el `role` destino y el mensaje de exito.
  Future<void> _promote(
    Emitter<UserManagementState> emit, {
    required String uid,
    required String role,
    required String successMessage,
  }) async {
    emit(const UserManagementLoading());
    final result = await updateUserRoleUseCase.call(uid: uid, role: role);
    await result.fold(
      (failure) async => emit(UserManagementError(failure.message)),
      (_) async {
        emit(UserManagementSuccess(successMessage));
        final reload = await getUsersUseCase.call();
        reload.fold(
          (failure) => emit(UserManagementError(failure.message)),
          (users) => emit(UserManagementLoaded(users: users)),
        );
      },
    );
  }
}
