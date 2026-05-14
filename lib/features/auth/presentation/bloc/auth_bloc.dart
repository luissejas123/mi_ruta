import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentAuthUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
  }) : super(const AuthInitial()) {
    on<RegisterEvent>(_onRegisterEvent);
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
    on<GetCurrentUserEvent>(_onGetCurrentUserEvent);
    on<ResetPasswordEvent>(_onResetPasswordEvent);
  }

  Future<void> _onRegisterEvent(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await registerUseCase.call(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      governmentId: event.governmentId,
      phoneNumber: event.phoneNumber,
      role: event.role,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.toString())),
      (user) => emit(AuthLoaded(user: user)),
    );
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await loginUseCase.call(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.toString())),
      (user) => emit(AuthLoaded(user: user)),
    );
  }

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logoutUseCase.call();

    result.fold(
      (failure) => emit(AuthError(message: failure.toString())),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onGetCurrentUserEvent(
    GetCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase.call();

    result.fold(
      (failure) => emit(AuthError(message: failure.toString())),
      (user) => emit(AuthLoaded(user: user)),
    );
  }

  Future<void> _onResetPasswordEvent(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await resetPasswordUseCase.call(event.email);

    result.fold(
      (failure) => emit(AuthError(message: failure.toString())),
      (_) => emit(
        const AuthSuccess(
          message: 'Verifica tu email para resetear la contraseña',
        ),
      ),
    );
  }
}
