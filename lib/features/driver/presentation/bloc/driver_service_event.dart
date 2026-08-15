import 'package:equatable/equatable.dart';

abstract class DriverServiceEvent extends Equatable {
  const DriverServiceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssignedVehicle extends DriverServiceEvent {
  final String driverUid;
  const LoadAssignedVehicle(this.driverUid);

  @override
  List<Object?> get props => [driverUid];
}

class StartService extends DriverServiceEvent {
  const StartService();
}

class StopService extends DriverServiceEvent {
  const StopService();
}
