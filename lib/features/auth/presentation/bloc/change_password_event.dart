import 'package:equatable/equatable.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object?> get props => [];
}

class ChangePasswordEventSubmit extends ChangePasswordEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEventSubmit({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
