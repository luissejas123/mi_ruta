import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/error/failures.dart';
import 'package:mi_ruta/features/user/data/datasources/geocoding_datasource.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';
import 'package:mi_ruta/features/user/domain/repositories/location_repository.dart';

/// Implementación del repositorio de ubicación que consume los DataSources locales.
class LocationRepositoryImpl implements LocationRepository {
  final LocationDatasource locationDatasource;
  final GeocodingDatasource geocodingDatasource;

  LocationRepositoryImpl({
    required this.locationDatasource,
    required this.geocodingDatasource,
  });

  @override
  Future<Either<Failure, LatLng>> getCurrentLocation() async {
    try {
      final result = await locationDatasource.getCurrentLocation();
      if (result.hasError) {
        return Left(ServerFailure(message: result.error ?? 'Error de ubicación'));
      }
      return Right(result.location);
    } catch (e) {
      return Left(ServerFailure(message: 'Error obteniendo la ubicación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> reverseGeocode(LatLng position) async {
    try {
      final address = await geocodingDatasource.reverseGeocode(position);
      if (address == null) {
        return Left(ServerFailure(message: 'No se pudo resolver la dirección'));
      }
      return Right(address);
    } catch (e) {
      return Left(ServerFailure(message: 'Error en geocodificación inversa: ${e.toString()}'));
    }
  }
}
