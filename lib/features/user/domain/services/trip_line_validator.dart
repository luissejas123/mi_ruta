/// Error de validación de un QR de cobro que debe mostrarse tal cual al
/// pasajero (sin el prefijo técnico "Exception: ..." de un error genérico).
class TripQrValidationException implements Exception {
  final String message;
  const TripQrValidationException(this.message);

  @override
  String toString() => message;
}

/// Compara la línea que el pasajero está abordando con la línea del viaje
/// al que apunta un QR de cobro, usando el `ref` GTFS de la línea (el mismo
/// que se guarda en `trips.route_ref` y que usan `RouteEntity.ref` /
/// `OsmRoute.ref`) — nunca el nombre de display (`route_name`), que no es
/// una llave estable.
///
/// El QR de cobro ("driverId|tripId|amount") no trae la línea: la línea del
/// QR se resuelve leyendo `trips/{tripId}.route_ref` en Firestore, así que no
/// se puede falsificar editando el texto del QR.
class TripLineValidator {
  static const mismatchMessage =
      'El código QR no corresponde a la línea de transporte seleccionada. '
      'Verifica la línea e intenta nuevamente.';
  static const unknownBoardedLineMessage =
      'No se pudo determinar la línea que estás abordando. '
      'Confirma tu abordaje e intenta nuevamente.';
  static const unknownQrLineMessage =
      'El código QR no indica a qué línea pertenece. '
      'Pide al chofer que genere un nuevo QR e intenta nuevamente.';
  static const tripMismatchMessage =
      'Este código QR no corresponde a tu viaje actual. '
      'Escanea el QR que te muestra el chofer de la unidad que abordaste.';

  /// `ref` normalizado (sin espacios, sin distinguir mayúsculas), o null si
  /// no hay un valor utilizable.
  static String? normalizeRef(Object? ref) {
    if (ref is! String) return null;
    final value = ref.trim().toLowerCase();
    return value.isEmpty ? null : value;
  }

  /// Lanza [TripQrValidationException] si no se puede confirmar que
  /// [qrRouteRef] (línea del viaje del QR) sea [boardedRouteRef] (línea
  /// abordada). Si falta cualquiera de los dos, no se permite el cobro.
  static void ensureSameLine({
    required Object? boardedRouteRef,
    required Object? qrRouteRef,
  }) {
    final boarded = normalizeRef(boardedRouteRef);
    if (boarded == null) {
      throw const TripQrValidationException(unknownBoardedLineMessage);
    }
    final qr = normalizeRef(qrRouteRef);
    if (qr == null) {
      throw const TripQrValidationException(unknownQrLineMessage);
    }
    if (boarded != qr) {
      throw const TripQrValidationException(mismatchMessage);
    }
  }
}
