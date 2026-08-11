import 'package:equatable/equatable.dart';

class TripHistoryEntry extends Equatable {
  final String id;
  final String userId;
  final String routeName;
  final String originName;
  final String destinationName;
  final Duration elapsed;
  final DateTime date;

  const TripHistoryEntry({
    required this.id,
    required this.userId,
    required this.routeName,
    required this.originName,
    required this.destinationName,
    required this.elapsed,
    required this.date,
  });

  @override
  List<Object?> get props => [id, userId, routeName, destinationName, elapsed, date];
}
