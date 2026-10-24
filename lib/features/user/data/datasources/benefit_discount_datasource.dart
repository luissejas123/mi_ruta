import 'package:cloud_firestore/cloud_firestore.dart';

/// Acceso a `config/benefit_discounts` — % de descuento por tipo de
/// beneficio ('student', 'university', 'senior', mismos valores que
/// `BenefitRequest.benefitType`), configurado por el admin. Mismo patrón
/// simple de un solo documento que `config/qr_recarga`.
class BenefitDiscountDatasource {
  final FirebaseFirestore _firestore;

  BenefitDiscountDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Devuelve el mapa tipo→porcentaje (0.0-1.0). Vacío si el admin todavía
  /// no configuró ningún descuento.
  Future<Map<String, double>> getDiscounts() async {
    final doc = await _firestore.collection('config').doc('benefit_discounts').get();
    final data = doc.data();
    if (data == null) return const {};
    final result = <String, double>{};
    for (final entry in data.entries) {
      if (entry.key == 'updated_at') continue;
      final value = entry.value;
      if (value is num) result[entry.key] = value.toDouble();
    }
    return result;
  }

  Future<void> setDiscounts(Map<String, double> percentByType) async {
    await _firestore.collection('config').doc('benefit_discounts').set({
      ...percentByType,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
