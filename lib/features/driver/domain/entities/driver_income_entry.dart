import 'package:equatable/equatable.dart';

class DriverIncomeEntry extends Equatable {
  final String id;
  final String driverId;
  final String passengerId;
  final String tripId;
  final double amount;
  final String description;
  final DateTime date;

  const DriverIncomeEntry({
    required this.id,
    required this.driverId,
    required this.passengerId,
    required this.tripId,
    required this.amount,
    required this.description,
    required this.date,
  });

  @override
  List<Object?> get props => [
    id,
    driverId,
    passengerId,
    tripId,
    amount,
    description,
    date,
  ];
}
