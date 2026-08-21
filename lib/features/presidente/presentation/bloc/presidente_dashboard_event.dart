import 'package:equatable/equatable.dart';

abstract class PresidenteDashboardEvent extends Equatable {
  const PresidenteDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadRoutesOverview extends PresidenteDashboardEvent {
  const LoadRoutesOverview();
}
