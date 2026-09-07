import 'package:equatable/equatable.dart';

class DriverOperationalStatus extends Equatable {
  final String id;
  final String name;
  final String line;
  final int completedTrips;
  final double rating;
  final bool isSuspended;
  // `users/{uid}.assigned_route_ref` — el campo REAL de línea del chofer
  // (ver DEUDA_TECNICA.md), distinto de `line` de arriba (derivado de
  // vehicles.line_number/trips.route_line, texto libre sin validar). Se usa
  // para filtrar "los choferes de mi línea" cuando quien mira el reporte es
  // un presidente con `managed_lines` — `line` no sirve para eso porque dos
  // grafías de la misma línea producirían conjuntos distintos.
  final String assignedRouteRef;

  const DriverOperationalStatus({
    required this.id,
    required this.name,
    required this.line,
    required this.completedTrips,
    required this.rating,
    required this.isSuspended,
    this.assignedRouteRef = '',
  });

  @override
  List<Object> get props => [
    id,
    name,
    line,
    completedTrips,
    rating,
    isSuspended,
    assignedRouteRef,
  ];
}

class OperationalReport extends Equatable {
  final List<DriverOperationalStatus> drivers;
  final int unitsInService;
  final int approvedUnits;
  final int unitsUnderReview;
  final int rejectedUnits;
  final int registeredPassengers;
  final int registeredTicketers;
  final int blockedAccounts;

  const OperationalReport({
    required this.drivers,
    required this.unitsInService,
    required this.approvedUnits,
    required this.unitsUnderReview,
    required this.rejectedUnits,
    required this.registeredPassengers,
    required this.registeredTicketers,
    required this.blockedAccounts,
  });

  @override
  List<Object?> get props => [drivers];

  /// Filtra a los choferes cuyo `assignedRouteRef` está entre [managedLines]
  /// (líneas que gestiona un presidente, `users.presidente_info.managed_lines`).
  /// [managedLines] vacío (admin, o presidente sin línea asignada todavía)
  /// devuelve la lista completa sin filtrar.
  List<DriverOperationalStatus> driversForLines(List<String> managedLines) {
    if (managedLines.isEmpty) return drivers;
    return drivers.where((d) => managedLines.contains(d.assignedRouteRef)).toList();
  }

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
