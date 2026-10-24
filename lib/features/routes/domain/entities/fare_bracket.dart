import 'package:equatable/equatable.dart';

/// Un tramo de la tarifa por distancia de una línea: hasta [maxKm]
/// kilómetros se cobra [fare]. `maxKm: null` significa "el resto" — el
/// último tramo de la lista, sin límite superior.
class FareBracket extends Equatable {
  final double? maxKm;
  final double fare;

  const FareBracket({required this.maxKm, required this.fare});

  Map<String, dynamic> toJson() => {'max_km': maxKm, 'fare': fare};

  factory FareBracket.fromJson(Map<String, dynamic> json) => FareBracket(
        maxKm: (json['max_km'] as num?)?.toDouble(),
        fare: (json['fare'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [maxKm, fare];
}

/// Tarifa por distancia configurada por el presidente para una línea.
class Tariff extends Equatable {
  final String routeRef;
  final List<FareBracket> brackets;
  final DateTime updatedAt;
  final String updatedBy;

  const Tariff({
    required this.routeRef,
    required this.brackets,
    required this.updatedAt,
    required this.updatedBy,
  });

  @override
  List<Object?> get props => [routeRef, brackets, updatedAt, updatedBy];
}

/// Resuelve la tarifa para [km] recorridos según [brackets] (se asume
/// ordenado ascendente por `maxKm`, el último con `maxKm: null`). Si
/// [brackets] está vacío no hay tarifa configurada para la línea — el
/// caller decide el respaldo (ver `TariffService.calculateFareForDistance`).
double? calculateFareForDistance(List<FareBracket> brackets, double km) {
  for (final bracket in brackets) {
    if (bracket.maxKm == null || km <= bracket.maxKm!) {
      return bracket.fare;
    }
  }
  return null;
}
