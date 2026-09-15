import 'package:equatable/equatable.dart';

enum NotificationType { trip, recharge, gift, operational }

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  // Gift-specific fields (null for non-gift notifications)
  final int? discountPercent;
  final String? businessName;
  final bool? isUsed;
  final DateTime? validUntil;
  // Presentes solo en el aviso operacional que el pasajero le manda al
  // chofer al tocar "Aviso de bajada" → "Escanear QR del chofer": el chofer
  // no tiene que teclear ni un monto ni buscar el viaje, ya vienen
  // conectados con el mismo `tripId` que se abrió al abordar.
  final String? relatedTripId;
  final double? relatedAmount;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.discountPercent,
    this.businessName,
    this.isUsed,
    this.validUntil,
    this.relatedTripId,
    this.relatedAmount,
  });

  AppNotification copyWith({bool? isRead, bool? isUsed}) => AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        discountPercent: discountPercent,
        businessName: businessName,
        isUsed: isUsed ?? this.isUsed,
        validUntil: validUntil,
        relatedTripId: relatedTripId,
        relatedAmount: relatedAmount,
      );

  @override
  List<Object?> get props => [
        id, userId, type, title, body, isRead, createdAt,
        discountPercent, businessName, isUsed, validUntil,
        relatedTripId, relatedAmount,
      ];
}
