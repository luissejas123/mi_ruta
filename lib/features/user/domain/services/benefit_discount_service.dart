import 'package:mi_ruta/features/user/data/datasources/benefit_discount_datasource.dart';

class BenefitDiscountService {
  final BenefitDiscountDatasource _datasource;

  BenefitDiscountService({required BenefitDiscountDatasource datasource})
      : _datasource = datasource;

  Future<Map<String, double>> getDiscounts() => _datasource.getDiscounts();

  Future<void> setDiscounts(Map<String, double> percentByType) =>
      _datasource.setDiscounts(percentByType);

  /// El mayor descuento aplicable entre los beneficios activos de la
  /// cuenta (si tiene más de uno aprobado, se usa el más beneficioso, no se
  /// suman). Devuelve 0.0 si no tiene beneficios o el admin no configuró
  /// ningún % para ninguno de ellos.
  double highestDiscountFor(
    List<String> activeBenefits,
    Map<String, double> discounts,
  ) {
    var best = 0.0;
    for (final benefit in activeBenefits) {
      final percent = discounts[benefit];
      if (percent != null && percent > best) best = percent;
    }
    return best.clamp(0.0, 1.0);
  }
}
