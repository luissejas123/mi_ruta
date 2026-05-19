import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class BenefitRequestEvent extends Equatable {
  const BenefitRequestEvent();

  @override
  List<Object?> get props => [];
}

class SubmitBenefitRequestEvent extends BenefitRequestEvent {
  final String userId;
  final String benefitType;
  final String description;
  final List<File> documentFiles;

  const SubmitBenefitRequestEvent({
    required this.userId,
    required this.benefitType,
    required this.description,
    required this.documentFiles,
  });

  @override
  List<Object?> get props => [userId, benefitType, description, documentFiles];
}

class LoadBenefitHistoryEvent extends BenefitRequestEvent {
  final String userId;

  const LoadBenefitHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ClearBenefitRequestEvent extends BenefitRequestEvent {
  const ClearBenefitRequestEvent();
}
