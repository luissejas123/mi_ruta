import 'package:flutter/material.dart';

/// Encabezado de sección reutilizado por cada bloque del home de tickeador
/// (CAMBIAR A MODO, MI ESTACIÓN, BUSCAR VEHÍCULO POR PLACA, ACTIVIDAD RECIENTE).
class TickeadorSectionTitle extends StatelessWidget {
  final String title;

  const TickeadorSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
