import 'package:equatable/equatable.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_legal_documents.dart';

/// Solicitud de un pasajero para convertirse en chofer, respaldada por un
/// vehículo con documentación legal. Mapea la colección `vehicles` ya
/// documentada en FIRESTORE_COLLECTIONS_GUIDE.md — el doc id es la placa
/// (`vehicle_id`), guardada también como campo espejo (mismo patrón que
/// `trips`/`trip_id`).
class Vehicle extends Equatable {
  final String id; // vehicle_id (placa) = doc id
  final String ownerUid;
  final String vehicleType; // 'taxitrufi' | 'micro' | ...
  final String lineNumber;
  final String internalNumber;
  final String brand;
  final String model;
  final String color;
  final int passengerCapacity;
  final String status; // 'pending_review' | 'approved' | 'rejected'
  final VehicleLegalDocuments legalDocuments;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.ownerUid,
    required this.vehicleType,
    required this.lineNumber,
    required this.internalNumber,
    required this.brand,
    required this.model,
    required this.color,
    required this.passengerCapacity,
    required this.status,
    required this.legalDocuments,
    required this.updatedAt,
  });

  bool get isPendingReview => status == 'pending_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        vehicleType,
        lineNumber,
        internalNumber,
        brand,
        model,
        color,
        passengerCapacity,
        status,
        legalDocuments,
        updatedAt,
      ];
}
