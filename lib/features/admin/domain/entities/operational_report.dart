import 'package:equatable/equatable.dart';

class DriverOperationalStatus extends Equatable {
  final String id;
  final String name;
  final String line;
  final int completedTrips;
  final double rating;
  final bool isSuspended;

  const DriverOperationalStatus({
    required this.id,
    required this.name,
    required this.line,
    required this.completedTrips,
    required this.rating,
    required this.isSuspended,
  });

  @override
  List<Object> get props => [
    id,
    name,
    line,
    completedTrips,
    rating,
    isSuspended,
  ];
}

class OperationalReport extends Equatable {
  final List<DriverOperationalStatus> drivers;

  const OperationalReport({required this.drivers});

  int get totalDrivers => drivers.length;
  List<DriverOperationalStatus> get suspendedDrivers =>
      drivers.where((driver) => driver.isSuspended).toList();
  List<DriverOperationalStatus> get featuredDrivers =>
      drivers
          .where((driver) => !driver.isSuspended && driver.rating >= 4.5)
          .toList()
        ..sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0
              ? byRating
              : b.completedTrips.compareTo(a.completedTrips);
        });
}
