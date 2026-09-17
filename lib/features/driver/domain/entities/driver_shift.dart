import 'package:equatable/equatable.dart';

/// Registro de una jornada de trabajo del chofer (RQ-82). Hoy vive en
/// memoria (`InMemoryDriverShiftRepository`) — cuando exista acceso a
/// Firestore real, se persistiría en una colección `driver_shifts` con los
/// mismos campos en snake_case (`vehicle_id`, `driver_uid`, `started_at`,
/// `ended_at`, `status`).
class DriverShiftEntity extends Equatable {
  final String id;
  final String vehicleId;
  final String driverUid;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // 'open' | 'closed'

  const DriverShiftEntity({
    required this.id,
    required this.vehicleId,
    required this.driverUid,
    required this.startedAt,
    this.endedAt,
    required this.status,
  });

  bool get isOpen => status == 'open';

  Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);

  DriverShiftEntity copyWith({DateTime? endedAt, String? status}) =>
      DriverShiftEntity(
        id: id,
        vehicleId: vehicleId,
        driverUid: driverUid,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props =>
      [id, vehicleId, driverUid, startedAt, endedAt, status];
}
