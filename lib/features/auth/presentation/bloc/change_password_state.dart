import 'package:equatable/equatable.dart';

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  final String message;

  const ChangePasswordSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ChangePasswordError extends ChangePasswordState {
  final String message;

  const ChangePasswordError(this.message);

  @override
  List<Object?> get props => [message];
}
