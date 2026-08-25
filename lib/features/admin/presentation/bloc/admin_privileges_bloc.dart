import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/domain/usecases/admin_usecases.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_privileges_state.dart';

class AdminPrivilegesBloc
    extends Bloc<AdminPrivilegesEvent, AdminPrivilegesState> {
  final GetAdminUsersUseCase getUsersUseCase;
  final GetAdminUserByIdUseCase getUserByIdUseCase;
  final UpdateAdminPermissionsUseCase updatePermissionsUseCase;
  final CreateAdminAccountUseCase createAdminAccountUseCase;

  AdminPrivilegesBloc({
    required this.getUsersUseCase,
    required this.getUserByIdUseCase,
    required this.updatePermissionsUseCase,
    required this.createAdminAccountUseCase,
  }) : super(const AdminPrivilegesInitial()) {
    on<LoadAdminsEvent>(_onLoadAdmins);
    on<LoadAdminPermissionsEvent>(_onLoadAdminPermissions);
    on<UpdateAdminPermissionsEvent>(_onUpdatePermissions);
    on<CreateAdminAccountEvent>(_onCreateAdminAccount);
  }

  Future<void> _onLoadAdmins(
    LoadAdminsEvent event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(const AdminPrivilegesLoading());
    final result = await getUsersUseCase.call();
    result.fold(
      (failure) => emit(AdminPrivilegesError(failure.message)),
      (users) {
        final admins = users.where((u) => u.isAdmin).toList();
        emit(AdminsLoaded(admins));
      },
    );
  }

  Future<void> _onLoadAdminPermissions(
    LoadAdminPermissionsEvent event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(const AdminPrivilegesLoading());
    final result = await getUserByIdUseCase.call(event.uid);
    result.fold(
      (failure) => emit(AdminPrivilegesError(failure.message)),
      (admin) => emit(AdminPermissionsLoaded(admin)),
    );
  }

  Future<void> _onUpdatePermissions(
    UpdateAdminPermissionsEvent event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(const AdminPrivilegesLoading());
    final result = await updatePermissionsUseCase.call(
      uid: event.uid,
      permissions: event.permissions,
    );
    result.fold(
      (failure) => emit(AdminPrivilegesError(failure.message)),
      (_) => emit(const AdminPrivilegesSuccess('Privilegios guardados')),
    );
  }

  Future<void> _onCreateAdminAccount(
    CreateAdminAccountEvent event,
    Emitter<AdminPrivilegesState> emit,
  ) async {
    emit(const AdminPrivilegesLoading());
    final result = await createAdminAccountUseCase.call(
      adminEmail: event.adminEmail,
      adminPassword: event.adminPassword,
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      governmentId: event.governmentId,
      phoneNumber: event.phoneNumber,
    );
    result.fold(
      (failure) => emit(AdminPrivilegesError(failure.message)),
      (_) async {
        emit(const AdminPrivilegesSuccess('Administrador creado correctamente'));
        final reload = await getUsersUseCase.call();
        reload.fold(
          (failure) => emit(AdminPrivilegesError(failure.message)),
          (users) => emit(AdminsLoaded(users.where((u) => u.isAdmin).toList())),
        );
      },
    );
  }
}
