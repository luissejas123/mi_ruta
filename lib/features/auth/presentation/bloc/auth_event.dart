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
  final String role;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.governmentId,
    required this.phoneNumber,
    required this.role,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    fullName,
    governmentId,
    phoneNumber,
    role,
  ];
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

class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}
