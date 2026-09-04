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
    );
    var hasError = false;
    result.fold(
      (failure) {
        hasError = true;
        emit(UserManagementError(failure.message));
      },
      (_) {},
    );
    if (hasError) return;

    emit(const UserManagementSuccess('Usuario promovido a administrador'));
    final reload = await getUsersUseCase.call();
    reload.fold(
      (failure) => emit(UserManagementError(failure.message)),
      (users) => emit(UserManagementLoaded(users: users)),
    );
  }
}
