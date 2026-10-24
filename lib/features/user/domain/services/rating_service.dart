import 'package:mi_ruta/features/user/data/datasources/rating_datasource.dart';

/// Pass-through sobre [RatingDatasource] — sin lógica de negocio propia
/// todavía, mismo patrón que el resto de servicios "delgados" del proyecto
/// (p. ej. `ClaimService`).
class RatingService {
  final RatingDatasource _datasource;

  RatingService({required RatingDatasource datasource}) : _datasource = datasource;

  Future<void> submitRating({
    required String tripId,
    required String reviewerUid,
    required String targetUid,
    required int stars,
    List<String> selectedTags = const [],
  }) {
    return _datasource.submitRating(
      tripId: tripId,
      reviewerUid: reviewerUid,
      targetUid: targetUid,
      stars: stars,
      selectedTags: selectedTags,
    );
  }
}
