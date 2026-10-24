import 'package:equatable/equatable.dart';

/// Nota informativa que el presidente marca sobre una ruta (ej. "calle
/// bloqueada en tal tramo") — no recalcula ni modifica el trazado real de
/// la ruta, es solo un aviso fechado para quien la consulte.
/// Ver docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 1.
class RouteDeviationNote extends Equatable {
  final String id;
  final String routeRef;
  final String note;
  final String reportedBy;
  final DateTime createdAt;
  final bool active;

  const RouteDeviationNote({
    required this.id,
    required this.routeRef,
    required this.note,
    required this.reportedBy,
    required this.createdAt,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, routeRef, note, reportedBy, createdAt, active];
}
