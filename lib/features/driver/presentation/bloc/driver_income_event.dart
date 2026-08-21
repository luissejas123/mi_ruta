import 'package:equatable/equatable.dart';

abstract class DriverIncomeEvent extends Equatable {
  const DriverIncomeEvent();
  @override
  List<Object?> get props => [];
}

class LoadDriverIncome extends DriverIncomeEvent {
  final String driverId;
  const LoadDriverIncome(this.driverId);
  @override
  List<Object?> get props => [driverId];
}
