import 'package:equatable/equatable.dart';

abstract class TripHistoryEvent extends Equatable {
  const TripHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadTripHistory extends TripHistoryEvent {
  final String userId;
  const LoadTripHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}
