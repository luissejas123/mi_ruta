import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/user/domain/entities/claim_entity.dart';

abstract class ClaimsState extends Equatable {
  const ClaimsState();
  @override
  List<Object?> get props => [];
}

class ClaimsInitial extends ClaimsState {}

class ClaimsLoading extends ClaimsState {}

class ClaimsLoaded extends ClaimsState {
  final List<ClaimEntity> claims;
  final List<String> lineIds;
  const ClaimsLoaded(this.claims, this.lineIds);

  List<ClaimEntity> get open => claims.where((c) => c.isOpen).toList();
  List<ClaimEntity> get resolved => claims.where((c) => !c.isOpen).toList();

  @override
  List<Object?> get props => [claims, lineIds];
}

class ClaimsError extends ClaimsState {
  final String message;
  const ClaimsError(this.message);
  @override
  List<Object?> get props => [message];
}
