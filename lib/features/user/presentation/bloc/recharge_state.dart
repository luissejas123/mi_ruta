import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/recharge.dart';

abstract class RechargeState extends Equatable {
  const RechargeState();

  @override
  List<Object?> get props => [];
}

class RechargeInitial extends RechargeState {
  const RechargeInitial();
}

class RechargeLoading extends RechargeState {
  const RechargeLoading();
}

class RechargeSubmitted extends RechargeState {
  final String rechargeId;
  final double amount;
  final String message;

  const RechargeSubmitted({
    required this.rechargeId,
    required this.amount,
    required this.message,
  });

  @override
  List<Object?> get props => [rechargeId, amount, message];
}

class RechargeHistoryLoaded extends RechargeState {
  final List<Recharge> recharges;

  const RechargeHistoryLoaded(this.recharges);

  @override
  List<Object?> get props => [recharges];
}

class RechargeStatusLoaded extends RechargeState {
  final Recharge recharge;

  const RechargeStatusLoaded(this.recharge);

  @override
  List<Object?> get props => [recharge];
}

class RechargeError extends RechargeState {
  final String message;
  final List<Recharge>? lastRecharges;

  const RechargeError({required this.message, this.lastRecharges});

  @override
  List<Object?> get props => [message, lastRecharges];
}
