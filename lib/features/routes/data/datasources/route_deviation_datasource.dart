import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/core/utils/firestore_date.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_deviation_note.dart';

/// Acceso a Firestore para `route_deviation_notes` (esquema documentado en
/// FIRESTORE_COLLECTIONS_GUIDE.md). Mismo patrón simple que `ClaimDatasource`.
class RouteDeviationDatasource {
  final FirebaseFirestore _firestore;

  RouteDeviationDatasource({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> createNote({
    required String routeRef,
    required String note,
    required String reportedBy,
  }) async {
    await _firestore.collection('route_deviation_notes').add({
      'route_ref': routeRef,
      'note': note,
      'reported_by': reportedBy,
      'created_at': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  Future<List<RouteDeviationNote>> getNotesForRoute(String routeRef) async {
    final snapshot = await _firestore
        .collection('route_deviation_notes')
        .where('route_ref', isEqualTo: routeRef)
        .get();
    final notes = snapshot.docs.map(_mapToNote).toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> setActive(String noteId, bool active) async {
    await _firestore.collection('route_deviation_notes').doc(noteId).update({'active': active});
  }

  RouteDeviationNote _mapToNote(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteDeviationNote(
      id: doc.id,
      routeRef: (data['route_ref'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      reportedBy: (data['reported_by'] ?? '').toString(),
      createdAt: parseFirestoreDate(data['created_at']) ?? DateTime.now(),
      active: data['active'] as bool? ?? true,
    );
  }
}
