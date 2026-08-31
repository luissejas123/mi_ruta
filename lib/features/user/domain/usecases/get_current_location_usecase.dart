import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/domain/repositories/location_repository.dart';

/// Caso de uso para obtener la ubicación GPS actual del dispositivo.
class GetCurrentLocationUseCase {
  final LocationRepository repository;

  GetCurrentLocationUseCase({required this.repository});

  Future<Either<Failure, LatLng>> call() async {
    return await repository.getCurrentLocation();
  }
}
