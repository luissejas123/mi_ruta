import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_ruta/features/user/domain/entities/movement_entity.dart';

/// Modelo de datos para el Movimiento de Billetera (Obs 4)
/// Implementa serialización y deserialización retrocompatible con Firestore
class MovementModel extends MovementEntity {
  const MovementModel({
    required super.id,
    required super.userId,
    required super.tipo,
    required super.monto,
    super.linea,
    super.ruta,
    super.viajeId,
    required super.fecha,
    required super.estado,
    required super.descripcion,
  });

  /// Parsea un DateTime desde diferentes formatos posibles en Firestore
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  /// Deserializa desde JSON con tolerancia a esquemas previos
  factory MovementModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final parsedTipo = MovementType.fromValue(
      (json['tipo'] ?? json['transaction_type']) as String?,
    );

    final rawAmount = (json['monto'] ?? json['amount'] as num?)?.toDouble() ?? 0.0;
    final parsedMonto = rawAmount.abs();

    final parsedLinea = (json['linea'] ??
            json['route_number'] ??
            json['route_line'] ??
            json['line_id'])
        ?.toString();

    final parsedRuta = (json['ruta'] ?? json['route_name'])?.toString();

    final parsedViajeId = (json['viaje_id'] ?? json['trip_id'])?.toString();

    final parsedFecha = _parseDate(
      json['fecha'] ?? json['timestamp'] ?? json['created_at'],
    );

    final parsedEstado = MovementStatus.fromValue(
      (json['estado'] ?? json['status']) as String?,
    );

    String? desc = (json['descripcion'] ?? json['description']) as String?;
    if (desc == null || desc.isEmpty) {
      switch (parsedTipo) {
        case MovementType.recarga:
          desc = 'Recarga de saldo';
          break;
        case MovementType.pagoViaje:
          if (parsedLinea != null && parsedLinea.isNotEmpty) {
            desc = 'Pago Línea $parsedLinea';
            if (parsedRuta != null && parsedRuta.isNotEmpty) {
              desc = '$desc - $parsedRuta';
            }
          } else {
            desc = 'Pago de viaje';
          }
          break;
        case MovementType.reembolso:
          desc = 'Reembolso de viaje';
          break;
        case MovementType.ajuste:
          desc = 'Movimiento de saldo';
          break;
      }
    }

    return MovementModel(
      id: docId ?? (json['id'] as String? ?? ''),
      userId: (json['user_id'] ?? json['userId']) as String? ?? '',
      tipo: parsedTipo,
      monto: parsedMonto,
      linea: parsedLinea,
      ruta: parsedRuta,
      viajeId: parsedViajeId,
      fecha: parsedFecha,
      estado: parsedEstado,
      descripcion: desc,
    );
  }

  /// Deserializa directamente desde un DocumentSnapshot de Firestore
  factory MovementModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MovementModel.fromJson(data, docId: doc.id);
  }

  /// Serializa a JSON asegurando los campos canónicos del modelo único y retrocompatibilidad
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tipo': tipo.toValue(),
      'monto': monto,
      if (linea != null) 'linea': linea,
      if (ruta != null) 'ruta': ruta,
      if (viajeId != null) 'viaje_id': viajeId,
      'fecha': Timestamp.fromDate(fecha),
      'estado': estado.toValue(),
      'descripcion': descripcion,
      // Retrocompatibilidad con esquemas anteriores
      'transaction_type': tipo.toValue(),
      'amount': monto,
      'timestamp': Timestamp.fromDate(fecha),
      'status': estado.toValue(),
      'description': descripcion,
      if (linea != null) 'route_number': linea,
      if (ruta != null) 'route_name': ruta,
      if (viajeId != null) 'trip_id': viajeId,
    };
  }
}
