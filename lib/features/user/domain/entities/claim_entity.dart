import 'package:equatable/equatable.dart';

/// Reclamo de un pasajero (esquema documentado en
/// FIRESTORE_COLLECTIONS_GUIDE.md, colección `claims` — existía especificada
/// y protegida en firestore.rules desde antes, pero sin ningún código que la
/// leyera o escribiera). Vocabulario de estado deliberadamente distinto al
/// de `benefit_requests`/`driver_request` (`pending`/`approved`/`rejected`):
/// un reclamo no se "aprueba", se resuelve. Mantener los dos vocabularios
/// separados es una decisión explícita (ver Retrospective/Padre), no un
/// descuido — no agregar un tercero.
class ClaimEntity extends Equatable {
  final String id;
  final String reporterId;
  final String? targetId;
  final String lineId;
  final String claimType; // 'driver' | 'user' | 'service'
  final String title;
  final String description;
  final String status; // 'open' | 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNote;
  // Solo para mostrar en la lista del presidente — no se persiste en el doc
  // de `claims`, se completa uniendo con `users` al leer.
  final String? reporterName;
  final String? targetName;

  const ClaimEntity({
    required this.id,
    required this.reporterId,
    this.targetId,
    required this.lineId,
    required this.claimType,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNote,
    this.reporterName,
    this.targetName,
  });

  bool get isOpen => status == 'open';

  ClaimEntity copyWith({String? reporterName, String? targetName}) => ClaimEntity(
        id: id,
        reporterId: reporterId,
        targetId: targetId,
        lineId: lineId,
        claimType: claimType,
        title: title,
        description: description,
        status: status,
        createdAt: createdAt,
        resolvedAt: resolvedAt,
        resolvedBy: resolvedBy,
        resolutionNote: resolutionNote,
        reporterName: reporterName ?? this.reporterName,
        targetName: targetName ?? this.targetName,
      );

  @override
  List<Object?> get props => [
        id,
        reporterId,
        targetId,
        lineId,
        claimType,
        title,
        description,
        status,
        createdAt,
        resolvedAt,
        resolvedBy,
        resolutionNote,
        reporterName,
        targetName,
      ];
}
