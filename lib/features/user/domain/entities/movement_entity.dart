import 'package:equatable/equatable.dart';

/// Tipos de movimientos admitidos en la billetera del pasajero
enum MovementType {
  recarga,
  pagoViaje,
  reembolso,
  ajuste;

  String toValue() {
    switch (this) {
      case MovementType.recarga:
        return 'recarga';
      case MovementType.pagoViaje:
        return 'pago_viaje';
      case MovementType.reembolso:
        return 'reembolso';
      case MovementType.ajuste:
        return 'ajuste';
    }
  }

  static MovementType fromValue(String? value) {
    if (value == null) return MovementType.ajuste;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'recarga' ||
        normalized == 'top_up' ||
        normalized == 'recharge') {
      return MovementType.recarga;
    }
    if (normalized == 'pago_viaje' ||
        normalized == 'pago' ||
        normalized == 'trip_payment' ||
        normalized == 'trip_payment_received') {
      return MovementType.pagoViaje;
    }
    if (normalized == 'reembolso' || normalized == 'refund') {
      return MovementType.reembolso;
    }
    return MovementType.ajuste;
  }
}

/// Estado de la transacción / movimiento
enum MovementStatus {
  completed,
  pending,
  rejected,
  cancelled;

  String toValue() {
    switch (this) {
      case MovementStatus.completed:
        return 'completed';
      case MovementStatus.pending:
        return 'pending';
      case MovementStatus.rejected:
        return 'rejected';
      case MovementStatus.cancelled:
        return 'cancelled';
    }
  }

  static MovementStatus fromValue(String? value) {
    if (value == null) return MovementStatus.completed;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'completed' || normalized == 'approved') {
      return MovementStatus.completed;
    }
    if (normalized == 'pending') {
      return MovementStatus.pending;
    }
    if (normalized == 'rejected' || normalized == 'failed') {
      return MovementStatus.rejected;
    }
    if (normalized == 'cancelled') {
      return MovementStatus.cancelled;
    }
    return MovementStatus.completed;
  }
}

/// Entidad única de Movimiento de Billetera (Obs 4)
/// Requeridos: tipo, monto, línea, ruta, viaje_id, fecha
class MovementEntity extends Equatable {
  final String id;
  final String userId;
  final MovementType tipo;
  final double monto; // Siempre positivo (en Bs.)
  final String? linea; // Código o número de línea (ej: "106", "138")
  final String? ruta; // Nombre de la ruta (ej: "Quillacollo - Cochabamba")
  final String? viajeId; // ID del viaje registrado (trip_id)
  final DateTime fecha; // Fecha y hora del movimiento
  final MovementStatus estado;
  final String descripcion;

  const MovementEntity({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.monto,
    this.linea,
    this.ruta,
    this.viajeId,
    required this.fecha,
    required this.estado,
    required this.descripcion,
  });

  /// Indica si el movimiento representa un ingreso de saldo a la billetera
  bool get isIncome =>
      tipo == MovementType.recarga || tipo == MovementType.reembolso;

  /// Retorna el valor algebraico para cálculo y cuadre de saldo:
  /// +monto si es ingreso (recarga/reembolso)
  /// -monto si es egreso (pago de viaje)
  double get signedAmount => isIncome ? monto : -monto;

  /// Retorna la etiqueta legible del tipo de movimiento
  String get tipoLabel {
    switch (tipo) {
      case MovementType.recarga:
        return 'Recarga de saldo';
      case MovementType.pagoViaje:
        return 'Pago de viaje';
      case MovementType.reembolso:
        return 'Reembolso';
      case MovementType.ajuste:
        return 'Ajuste de saldo';
    }
  }

  /// Retorna un texto formateado del monto con signo (+ Bs. X.XX / - Bs. X.XX)
  String get formattedSignedAmount {
    final prefix = isIncome ? '+' : '-';
    return '$prefix Bs. ${monto.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    tipo,
    monto,
    linea,
    ruta,
    viajeId,
    fecha,
    estado,
    descripcion,
  ];
}
