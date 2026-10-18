import 'package:flutter/material.dart';

/// Botón de ancho completo para acciones de pago/recarga.
///
/// Mientras [isLoading] sea `true` el botón queda deshabilitado
/// (`onPressed == null`) y muestra un indicador de carga, por lo que ignora
/// cualquier toque posterior al primero hasta que la operación termine.
class PaymentButton extends StatelessWidget {
  static const _amarillo = Color(0xFFFFC12F);

  /// Texto del botón en estado normal.
  final String label;

  /// Texto mostrado mientras la operación está en curso.
  final String loadingLabel;

  /// Ícono opcional en estado normal (al cargar se reemplaza por el spinner).
  final IconData? icon;

  /// `true` desde el primer toque hasta que la operación termina.
  final bool isLoading;

  final VoidCallback onPressed;
  final double height;

  const PaymentButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.loadingLabel = 'Procesando...',
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: _amarillo,
      // Amarillo atenuado para que el estado "procesando" siga siendo visible.
      disabledBackgroundColor: _amarillo.withValues(alpha: 0.55),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    final text = Text(
      isLoading ? loadingLabel : label,
      style: TextStyle(
        color: isLoading ? Colors.black54 : Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: isLoading
          ? ElevatedButton.icon(
              onPressed: null,
              icon: const PaymentLoadingIndicator(),
              label: text,
              style: style,
            )
          : icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.black),
              label: text,
              style: style,
            )
          : ElevatedButton(onPressed: onPressed, style: style, child: text),
    );
  }
}

/// Indicador de carga usado dentro de los botones de pago.
class PaymentLoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const PaymentLoadingIndicator({
    super.key,
    this.size = 20,
    this.color = Colors.black54,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}
