import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/repositories/location_repository.dart';

/// Caso de uso para obtener la dirección aproximada de una coordenada geográfica.
class ReverseGeocodeUseCase {
  final LocationRepository repository;

  ReverseGeocodeUseCase({required this.repository});

  Future<Either<Failure, String>> call(LatLng position) async {
    return await repository.reverseGeocode(position);
  }
}
