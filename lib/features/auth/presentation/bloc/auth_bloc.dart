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
  final LoginAsDemoUseCase loginAsDemoUseCase;

  AuthBloc({
    required this.registerUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.loginAsDemoUseCase,
  }) : super(const AuthInitial()) {
    on<RegisterEvent>(_onRegisterEvent);
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
    on<GetCurrentUserEvent>(_onGetCurrentUserEvent);
    on<ResetPasswordEvent>(_onResetPasswordEvent);
    on<LoginAsDemoEvent>(_onLoginAsDemoEvent);
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
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        // AuthSuccess dispara la navegación a RegistrationSuccessPage (ver
        // RegisterPage); AuthLoaded deja el estado global correcto de una
        // vez, para que el resto de la app (perfil, wallet, etc.) no se
        // quede esperando una sesión "cerrada" hasta el próximo reinicio.
        emit(const AuthSuccess(message: 'Registro exitoso'));
        emit(AuthLoaded(user: user));
      },
    );
  }

  Future<void> _onLoginEvent(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await loginUseCase.call(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
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
      (failure) => emit(AuthError(message: failure.message)),
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
      (failure) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthLoaded(user: user)),
    );
  }

  /// TEMPORAL — modo prueba 100% estático: sin Firebase ni Firestore.
  Future<void> _onLoginAsDemoEvent(
    LoginAsDemoEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await loginAsDemoUseCase(role: event.role);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
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
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(
        const AuthSuccess(
          message: 'Verifica tu email para resetear la contraseña',
        ),
      ),
    );
  }
}