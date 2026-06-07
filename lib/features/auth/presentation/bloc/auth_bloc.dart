import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/utils/validators.dart';
import 'package:mi_ruta/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase registerUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentAuthUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  // Almacena errores de validación por campo
  Map<String, String> _currentFieldErrors = {};

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
    on<ValidateRegistrationFieldEvent>(_onValidateRegistrationField);
  }

  /// Valida un campo individual del registro y actualiza el estado
  Future<void> _onValidateRegistrationField(
    ValidateRegistrationFieldEvent event,
    Emitter<AuthState> emit,
  ) async {
    String? error;

    // Validar según el nombre del campo
    switch (event.fieldName) {
      case 'fullName':
        error = FormValidators.validateFullName(event.fieldValue);
        break;
      case 'governmentId':
        error = FormValidators.validateGovernmentId(event.fieldValue);
        break;
      case 'phoneNumber':
        error = FormValidators.validatePhoneNumber(event.fieldValue);
        break;
      case 'email':
        error = FormValidators.validateEmail(event.fieldValue);
        break;
      case 'password':
        error = FormValidators.validatePassword(event.fieldValue);
        break;
      case 'confirmPassword':
        error = FormValidators.validatePasswordMatch(
          event.confirmPassword ?? '',
          event.fieldValue,
        );
        break;
    }

    // Actualizar el diccionario de errores
    if (error != null) {
      _currentFieldErrors[event.fieldName] = error;
    } else {
      _currentFieldErrors.remove(event.fieldName);
    }

    // Emitir el estado con los errores actualizados
    emit(
      AuthValidationError(
        fieldErrors: Map.from(_currentFieldErrors),
        isFormValid: _currentFieldErrors.isEmpty,
      ),
    );
  }

  Future<void> _onRegisterEvent(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Validar todos los campos antes de intentar registrar
    final validationErrors = FormValidators.validateAllRegistrationFields(
      fullName: event.fullName,
      governmentId: event.governmentId,
      phoneNumber: event.phoneNumber,
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
    );

    if (validationErrors.isNotEmpty) {
      _currentFieldErrors = validationErrors;
      emit(
        AuthValidationError(
          fieldErrors: validationErrors,
          isFormValid: false,
        ),
      );
      return;
    }

    // Todos los campos son válidos, proceder con el registro
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
      (failure) {
        // Manejar errores específicos de Firebase
        String errorMessage = failure.toString();
        if (errorMessage.contains('email-already-in-use')) {
          errorMessage = 'Este correo ya está registrado';
          _currentFieldErrors['email'] = errorMessage;
          emit(
            AuthValidationError(
              fieldErrors: {'email': errorMessage},
              isFormValid: false,
            ),
          );
        } else if (errorMessage.contains('weak-password')) {
          errorMessage = 'La contraseña es muy débil';
          emit(AuthError(message: errorMessage));
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = 'El correo no es válido';
          _currentFieldErrors['email'] = errorMessage;
          emit(
            AuthValidationError(
              fieldErrors: {'email': errorMessage},
              isFormValid: false,
            ),
          );
        } else {
          emit(AuthError(message: errorMessage));
        }
      },
      (user) {
        _currentFieldErrors.clear();
        emit(AuthLoaded(user: user));
      },
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
