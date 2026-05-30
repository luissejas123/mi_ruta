/// Service de utilidades para la página de pago QR.
/// Contiene lógica pura para extraer y procesar datos del pago.
class PagoQRUtilsService {
  /// Formato de monto a string con símbolo de moneda.
  static String formatAmount(double amount) =>
      'Bs. ${amount.toStringAsFixed(2)}';

  /// Valida que el resultado del QR no sea nulo ni vacío.
  static bool isValidQrResult(String? qrResult) =>
      qrResult != null && qrResult.isNotEmpty;
}
