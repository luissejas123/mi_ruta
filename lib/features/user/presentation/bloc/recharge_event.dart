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

/// Carga todas las recargas pendientes de cualquier usuario — pantalla de
/// revisión del tickeador (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 0).
class LoadPendingRechargesEvent extends RechargeEvent {
  const LoadPendingRechargesEvent();
}

class ApproveRechargeEvent extends RechargeEvent {
  final String rechargeId;
  final String userId;
  final double amount;

  const ApproveRechargeEvent({
    required this.rechargeId,
    required this.userId,
    required this.amount,
  });

  @override
  List<Object?> get props => [rechargeId, userId, amount];
}

class RejectRechargeEvent extends RechargeEvent {
  final String rechargeId;
  final String userId;
  final double amount;
  final String reason;

  const RejectRechargeEvent({
    required this.rechargeId,
    required this.userId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object?> get props => [rechargeId, userId, amount, reason];
}
