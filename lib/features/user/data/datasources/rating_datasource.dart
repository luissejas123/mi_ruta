import 'package:cloud_firestore/cloud_firestore.dart';

/// Acceso a Firestore para `ratings` (esquema documentado en
/// FIRESTORE_COLLECTIONS_GUIDE.md: `trip_id`, `reviewer_uid`, `target_uid`,
/// `stars`, `selected_tags`, `created_at`). Antes solo se leía (reporte
/// operativo del admin); este es el primer escritor. El esquema ya es
/// bidireccional por diseño (reviewer/target genéricos, no
/// "passenger_uid"/"driver_uid"), así que el mismo método sirve tanto para
/// que el pasajero califique al chofer como para que el chofer califique al
/// pasajero — no hace falta una segunda colección ni campos paralelos.
class RatingDatasource {
  final FirebaseFirestore _firestore;

  RatingDatasource({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> submitRating({
    required String tripId,
    required String reviewerUid,
    required String targetUid,
    required int stars,
    List<String> selectedTags = const [],
  }) async {
    await _firestore.collection('ratings').add({
      'trip_id': tripId,
      'reviewer_uid': reviewerUid,
      'target_uid': targetUid,
      'stars': stars,
      'selected_tags': selectedTags,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
