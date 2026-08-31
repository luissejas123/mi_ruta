import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RechargeEvent extends Equatable {
  const RechargeEvent();

  @override
  List<Object?> get props => [];
}

class SubmitRechargeEvent extends RechargeEvent {
  final String userId;
  final double amount;
  final File proofImageFile;

  const SubmitRechargeEvent({
    required this.userId,
    required this.amount,
    required this.proofImageFile,
  });

  @override
  List<Object?> get props => [userId, amount, proofImageFile];
}

class LoadRechargeHistoryEvent extends RechargeEvent {
  final String userId;

  const LoadRechargeHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadRechargeStatusEvent extends RechargeEvent {
  final String rechargeId;

  const LoadRechargeStatusEvent(this.rechargeId);

  @override
  List<Object?> get props => [rechargeId];
}

class ClearRechargeEvent extends RechargeEvent {
  const ClearRechargeEvent();
}
