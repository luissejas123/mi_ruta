import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String governmentId;
  final String phoneNumber;
  final String confirmPassword;
  final String role;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.governmentId,
    required this.phoneNumber,
    required this.confirmPassword,
    required this.role,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    fullName,
    governmentId,
    phoneNumber,
    confirmPassword,
    role,
  ];
}

class ValidateRegistrationFieldEvent extends AuthEvent {
  final String fieldName;
  final String fieldValue;
  final String? confirmPassword; // Para validar coincidencia de contraseñas

  const ValidateRegistrationFieldEvent({
    required this.fieldName,
    required this.fieldValue,
    this.confirmPassword,
  });

  @override
  List<Object?> get props => [fieldName, fieldValue, confirmPassword];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class GetCurrentUserEvent extends AuthEvent {
  const GetCurrentUserEvent();
}

class ValidateLoginFieldEvent extends AuthEvent {
  final String fieldName;
  final String fieldValue;

  const ValidateLoginFieldEvent({
    required this.fieldName,
    required this.fieldValue,
  });

  @override
  List<Object?> get props => [fieldName, fieldValue];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
