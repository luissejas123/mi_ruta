import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_income_entry.dart';

abstract class DriverIncomeState extends Equatable {
  const DriverIncomeState();
  @override
  List<Object?> get props => [];
}

class DriverIncomeInitial extends DriverIncomeState {}

class DriverIncomeLoading extends DriverIncomeState {}

class DriverIncomeLoaded extends DriverIncomeState {
  final List<DriverIncomeEntry> entries;
  final double totalIncome;
  const DriverIncomeLoaded(this.entries, this.totalIncome);
  @override
  List<Object?> get props => [entries, totalIncome];
}

class DriverIncomeError extends DriverIncomeState {
  final String message;
  const DriverIncomeError(this.message);
  @override
  List<Object?> get props => [message];
}
