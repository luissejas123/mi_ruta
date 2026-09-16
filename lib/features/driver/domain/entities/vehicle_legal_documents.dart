import 'package:equatable/equatable.dart';

/// Documentos legales de un vehículo, subidos a Firebase Storage.
/// Mapea 1:1 el campo `legal_documentation` de la colección `vehicles`
/// (ver FIRESTORE_COLLECTIONS_GUIDE.md) — no introduce campos nuevos.
class VehicleLegalDocuments extends Equatable {
  final String soatUrl;
  final String vehicleInspectionUrl;
  final String driverLicenseUrl;
  final String municipalOperationCardUrl;
  final String ruatUrl;

  const VehicleLegalDocuments({
    required this.soatUrl,
    required this.vehicleInspectionUrl,
    required this.driverLicenseUrl,
    required this.municipalOperationCardUrl,
    required this.ruatUrl,
  });

  @override
  List<Object?> get props => [
        soatUrl,
        vehicleInspectionUrl,
        driverLicenseUrl,
        municipalOperationCardUrl,
        ruatUrl,
      ];
}
