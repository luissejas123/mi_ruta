import 'package:equatable/equatable.dart';

/// Tarifa por km de una línea (RQ-121). Hoy vive en memoria
/// (`InMemoryTariffRepository`) — cuando exista acceso a Firestore real, se
/// persistiría en `tariffs/{route_ref}` con los mismos campos en
/// snake_case (`route_ref` como id del doc, `price_per_km`, `updated_by`,
/// `updated_at`).
class TariffEntity extends Equatable {
  final String routeRef;
  final double pricePerKmBs;
  final DateTime updatedAt;

  const TariffEntity({
    required this.routeRef,
    required this.pricePerKmBs,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [routeRef, pricePerKmBs, updatedAt];
}
