import 'package:flutter/material.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_assigned_routes_page.dart'
    show AssignedRouteCard;
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

/// Muestra el recorrido de una línea en el mapa — al tocar una tarjeta en
/// "Paradas cercanas" (ver `paradas_cercanas_page.dart`). Reusa
/// `AssignedRouteCard` (mismo widget que ya usan chofer/presidente para
/// dibujar línea + mapa), sin nada de interacción de staff.
class RutaMapaPasajeroPage extends StatelessWidget {
  final RouteEntity route;

  const RutaMapaPasajeroPage({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Línea ${route.ref}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AssignedRouteCard(route: route),
      ),
    );
  }
}
