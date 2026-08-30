import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';

/// Navega entre las 4 pestañas del pie de navegación compartido
/// (Inicio/Billetera/Rutas/Perfil). [homeBuilder] permite que un perfil
/// distinto al pasajero (chofer, admin, tickeador, dirigente) defina a qué
/// pantalla vuelve "Inicio" — por defecto es MiRutaScreen (pasajero).
/// [walletBuilder]/[routesBuilder] permiten lo mismo para las pestañas
/// Billetera/Rutas — hoy solo el chofer los usa (su Billetera y su Rutas no
/// son las del pasajero); el resto de llamadores no los pasa y sigue yendo
/// a [WalletPage]/[RutasInicioPage] sin cambios.
void navigateBottomNav(
  BuildContext context,
  int index, {
  WidgetBuilder? homeBuilder,
  WidgetBuilder? walletBuilder,
  WidgetBuilder? routesBuilder,
}) {
  late Widget destination;

  switch (index) {
    case 0:
      destination = homeBuilder != null ? homeBuilder(context) : const MiRutaScreen();
      break;
    case 1:
      destination = walletBuilder != null
          ? walletBuilder(context)
          : WalletPage(homeBuilder: homeBuilder);
      break;
    case 2:
      destination = routesBuilder != null
          ? routesBuilder(context)
          : RutasInicioPage(homeBuilder: homeBuilder);
      break;
    case 3:
      // ✅ Ahora va al perfil real
      destination = PerfilPage(homeBuilder: homeBuilder);
      break;
    default:
      return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}