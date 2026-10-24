import 'package:equatable/equatable.dart';

/// Entidad que representa la información del Tickeador (operador de terminal).
///
/// Los campos corresponden exactamente a los definidos en la estructura
/// `tickeador_info` de la colección `users` en Firestore.
class TickeadorEntity extends Equatable {
  /// Estación asignada al tickeador (ej: "Terminal Sur").
  final String? assignedStation;

  /// Líneas de transporte asignadas (ej: ["line_138", "line_200"]).
  final List<String> assignedLines;

  /// Estado del tickeador (ej: "active").
  final String status;

  const TickeadorEntity({
    this.assignedStation,
    this.assignedLines = const [],
    this.status = 'active',
  });

  /// Construye una entidad Tickeador desde el mapa `tickeador_info`
  /// almacenado en Firestore.
  factory TickeadorEntity.fromJson(Map<String, dynamic> json) {
    return TickeadorEntity(
      assignedStation: json['assigned_station'] as String?,
      assignedLines:
          (json['assigned_lines'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      status: json['status'] as String? ?? 'active',
    );
  }

  @override
  List<Object?> get props => [assignedStation, assignedLines, status];
}
