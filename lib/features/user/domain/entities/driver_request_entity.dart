import 'package:equatable/equatable.dart';

/// Estado de la solicitud de un pasajero para convertirse en chofer.
/// Corresponde al mapa `driver_request` de la colección `users`.
///
/// El `role` de la cuenta **no** cambia hasta la aprobación: si cambiara al
/// solicitar, el ruteo por rol mandaría al usuario a la pantalla de chofer
/// antes de tiempo (ver `homeScreenForRole`).
enum DriverRequestStatus { pending, approved, rejected }

class DriverRequestEntity extends Equatable {
  final DriverRequestStatus status;

  /// `requested_at` en Firestore, string ISO 8601 igual que `created_at` de
  /// `users` (esa colección usa ISO, no Timestamp nativo).
  final DateTime? requestedAt;

  const DriverRequestEntity({required this.status, this.requestedAt});

  bool get isPending => status == DriverRequestStatus.pending;

  static DriverRequestStatus statusFromString(String? value) {
    switch (value) {
      case 'approved':
        return DriverRequestStatus.approved;
      case 'rejected':
        return DriverRequestStatus.rejected;
      default:
        return DriverRequestStatus.pending;
    }
  }

  static String statusToString(DriverRequestStatus status) => status.name;

  /// Devuelve `null` si el documento no tiene solicitud, para poder distinguir
  /// "nunca solicitó" de "solicitó y fue rechazado".
  static DriverRequestEntity? fromJson(dynamic json) {
    if (json is! Map) return null;
    final raw = json['requested_at'];
    DateTime? requestedAt;
    if (raw is String) {
      requestedAt = DateTime.tryParse(raw);
    } else if (raw != null) {
      // Tolera un Timestamp nativo si alguna escritura antigua lo dejó asi.
      try {
        requestedAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    return DriverRequestEntity(
      status: statusFromString(json['status'] as String?),
      requestedAt: requestedAt,
    );
  }

  @override
  List<Object?> get props => [status, requestedAt];
}
