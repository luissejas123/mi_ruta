import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/tickeador_operation.dart';

abstract class TickeadorOperationsState extends Equatable {
  const TickeadorOperationsState();

  @override
  List<Object?> get props => [];
}

class TickeadorOperationsInitial extends TickeadorOperationsState {}

class TickeadorOperationsLoading extends TickeadorOperationsState {}

class TickeadorOperationSaving extends TickeadorOperationsState {}

class TickeadorOperationSaved extends TickeadorOperationsState {}

class TickeadorOperationsLoaded extends TickeadorOperationsState {
  final List<TickeadorOperation> operations;

  const TickeadorOperationsLoaded(this.operations);

  @override
  List<Object?> get props => [operations];
}

class TickeadorOperationsError extends TickeadorOperationsState {
  final String message;

  const TickeadorOperationsError(this.message);

  @override
  List<Object?> get props => [message];
}
