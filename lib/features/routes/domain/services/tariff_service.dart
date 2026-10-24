import 'package:mi_ruta/features/routes/data/datasources/tariff_datasource.dart';
import 'package:mi_ruta/features/routes/domain/entities/fare_bracket.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';

/// Tarifa por defecto cuando una línea todavía no tiene `tariffs/{ref}`
/// configurado — un único tramo con la tarifa plana histórica del proyecto
/// (2.5 Bs), para no romper el cobro mientras el presidente configura su
/// línea por primera vez.
const _defaultBrackets = [FareBracket(maxKm: null, fare: 2.5)];

class TariffService {
  final TariffDatasource _datasource;

  TariffService({required TariffDatasource datasource}) : _datasource = datasource;

  Future<Tariff?> getTariff(String routeRef) => _datasource.getTariff(routeRef);

  Future<void> setTariff({
    required String routeRef,
    required List<FareBracket> brackets,
    required String updatedBy,
  }) =>
      _datasource.setTariff(routeRef: routeRef, brackets: brackets, updatedBy: updatedBy);

  /// Aplica la misma tarifa a un grupo de líneas de una sola vez — un
  /// presidente que gestiona varias líneas no tiene por qué repetir el
  /// mismo formulario una por una si quiere la misma tarifa para todas
  /// (docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, seguimiento QA).
  Future<void> setTariffForLines({
    required List<String> routeRefs,
    required List<FareBracket> brackets,
    required String updatedBy,
  }) async {
    await Future.wait(
      routeRefs.map(
        (ref) => setTariff(routeRef: ref, brackets: brackets, updatedBy: updatedBy),
      ),
    );
  }

  /// Tarifa para [km] recorridos en la línea [routeRef]. Si la línea no
  /// tiene tarifa configurada todavía, usa [_defaultBrackets].
  Future<double> resolveFareForDistance(String routeRef, double km) async {
    final brackets = await _bracketsFor(routeRef);
    return calculateFareForDistance(brackets, km) ?? brackets.last.fare;
  }

  /// Tarifa máxima (último tramo) de [routeRef] — se cobra cuando el
  /// pasajero nunca avisa que bajó (política de respaldo, ver
  /// docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, paso 3).
  Future<double> resolveMaxFare(String routeRef) async {
    final brackets = await _bracketsFor(routeRef);
    return brackets.last.fare;
  }

  Future<List<FareBracket>> _bracketsFor(String routeRef) async {
    final tariff = await getTariff(routeRef);
    return (tariff == null || tariff.brackets.isEmpty) ? _defaultBrackets : tariff.brackets;
  }

  /// Costo total estimado de [trip] según la tarifa real configurada por
  /// tramo de bus (`transitMeters`/`routeRef` de cada `PlannedTripLeg`) — en
  /// vez del monto plano `busLegs.length * 2.5` que se mostraba antes sin
  /// mirar la distancia real ni la tarifa de la línea (ver
  /// `PlannedTrip.totalCostBs`, que sigue existiendo como respaldo síncrono
  /// para pantallas que no pueden esperar esta consulta async).
  /// docs/PLAN_SEGURIDAD_TARIFAS_GPS.md, Bloque 2, paso 3.
  Future<double> resolvePlannedTripFare(PlannedTrip trip) async {
    var total = 0.0;
    for (final leg in trip.busLegs) {
      total += await resolveFareForDistance(leg.routeRef, leg.transitMeters / 1000);
    }
    return total;
  }
}
