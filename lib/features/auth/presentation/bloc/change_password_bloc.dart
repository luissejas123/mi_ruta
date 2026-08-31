import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/change_password_state.dart';

/// BLoC dedicado al cambio de contraseña del usuario autenticado.
///
/// Usa estados propios para no alterar los estados globales de AuthBloc,
/// que controlan la navegación de la app.
class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordBloc({required this.changePasswordUseCase})
      : super(const ChangePasswordInitial()) {
    on<ChangePasswordEventSubmit>(_onChangePassword);
  }

  Future<void> _onChangePassword(
    ChangePasswordEventSubmit event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());
    final result = await changePasswordUseCase.call(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(ChangePasswordError(failure.message)),
      (_) => emit(const ChangePasswordSuccess('Contraseña actualizada')),
    );
  }
}
