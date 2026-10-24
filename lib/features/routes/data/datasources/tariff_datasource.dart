import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/routes/domain/entities/fare_bracket.dart';

/// Acceso a Firestore para `tariffs` (esquema documentado en
/// FIRESTORE_COLLECTIONS_GUIDE.md). El ref de línea es el ID del documento
/// (no un campo) para que la regla de Firestore pueda exigir "solo tu
/// línea" de forma nativa — ver firestore.rules.
class TariffDatasource {
  final FirebaseFirestore _firestore;

  TariffDatasource({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<Tariff?> getTariff(String routeRef) async {
    final doc = await _firestore.collection('tariffs').doc(routeRef).get();
    if (!doc.exists) return null;
    return _mapToTariff(doc);
  }

  Future<void> setTariff({
    required String routeRef,
    required List<FareBracket> brackets,
    required String updatedBy,
  }) async {
    await _firestore.collection('tariffs').doc(routeRef).set({
      'brackets': brackets.map((b) => b.toJson()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': updatedBy,
    });
  }

  Tariff _mapToTariff(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawBrackets = data['brackets'];
    final brackets = rawBrackets is List
        ? rawBrackets
            .whereType<Map<String, dynamic>>()
            .map(FareBracket.fromJson)
            .toList()
        : <FareBracket>[];
    return Tariff(
      routeRef: doc.id,
      brackets: brackets,
      updatedAt: parseFirestoreDate(data['updated_at']) ?? DateTime.now(),
      updatedBy: (data['updated_by'] ?? '').toString(),
    );
  }
}
