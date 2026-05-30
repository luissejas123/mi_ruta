import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/error/failures.dart';

/// Contrato para el repositorio de ubicación y geocodificación.
/// Utiliza el tipo `Either` para el manejo robusto de errores.
abstract class LocationRepository {
  /// Obtiene la ubicación GPS actual del dispositivo.
  Future<Either<Failure, LatLng>> getCurrentLocation();

  /// Realiza la geocodificación inversa para obtener una dirección legible
  /// a partir de coordenadas geográficas.
  Future<Either<Failure, String>> reverseGeocode(LatLng position);
}
