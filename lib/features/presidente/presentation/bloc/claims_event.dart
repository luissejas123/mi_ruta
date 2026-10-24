import 'package:equatable/equatable.dart';

abstract class ClaimsEvent extends Equatable {
  const ClaimsEvent();
  @override
  List<Object?> get props => [];
}

class LoadClaims extends ClaimsEvent {
  final List<String> lineIds;
  const LoadClaims({this.lineIds = const []});
  @override
  List<Object?> get props => [lineIds];
}

class ResolveClaim extends ClaimsEvent {
  final String claimId;
  final String resolvedBy;
  final String? resolutionNote;
  const ResolveClaim({required this.claimId, required this.resolvedBy, this.resolutionNote});
  @override
  List<Object?> get props => [claimId, resolvedBy, resolutionNote];
}
