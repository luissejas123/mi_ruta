import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthLoaded extends AuthState {
  final AuthEntity user;

  const AuthLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthSuccess extends AuthState {
  final String message;

  const AuthSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado que contiene errores de validación por campo
/// Útil para mostrar errores en tiempo real debajo de cada campo
class AuthValidationError extends AuthState {
  final Map<String, String> fieldErrors;
  final bool isFormValid;

  const AuthValidationError({
    required this.fieldErrors,
    this.isFormValid = false,
  });

  @override
  List<Object?> get props => [fieldErrors, isFormValid];
}

/// Estado específico para validación de login
class LoginValidationError extends AuthState {
  final Map<String, String> fieldErrors;
  final bool isFormValid;

  const LoginValidationError({
    required this.fieldErrors,
    this.isFormValid = false,
  });

  @override
  List<Object?> get props => [fieldErrors, isFormValid];
}
