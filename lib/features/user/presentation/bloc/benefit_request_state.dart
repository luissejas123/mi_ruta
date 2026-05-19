import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/benefit_request.dart';

abstract class BenefitRequestState extends Equatable {
  const BenefitRequestState();

  @override
  List<Object?> get props => [];
}

class BenefitRequestInitial extends BenefitRequestState {
  const BenefitRequestInitial();
}

class BenefitRequestLoading extends BenefitRequestState {
  const BenefitRequestLoading();
}

class BenefitRequestSubmitted extends BenefitRequestState {
  final String requestId;
  final String benefitType;
  final String message;

  const BenefitRequestSubmitted({
    required this.requestId,
    required this.benefitType,
    required this.message,
  });

  @override
  List<Object?> get props => [requestId, benefitType, message];
}

class BenefitHistoryLoaded extends BenefitRequestState {
  final List<BenefitRequest> requests;

  const BenefitHistoryLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class BenefitRequestError extends BenefitRequestState {
  final String message;

  const BenefitRequestError({required this.message});

  @override
  List<Object?> get props => [message];
}
