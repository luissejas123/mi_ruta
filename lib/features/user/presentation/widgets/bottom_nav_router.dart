import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';

/// Navega entre las 4 pestañas del pie de navegación compartido
/// (Inicio/Billetera/Rutas/Perfil). [homeBuilder] permite que un perfil
/// distinto al pasajero (chofer, admin, tickeador, dirigente) defina a qué
/// pantalla vuelve "Inicio" — por defecto es MiRutaScreen (pasajero).
void navigateBottomNav(
  BuildContext context,
  int index, {
  WidgetBuilder? homeBuilder,
}) {
  late Widget destination;

  switch (index) {
    case 0:
      destination = homeBuilder != null ? homeBuilder(context) : const MiRutaScreen();
      break;
    case 1:
      destination = WalletPage(homeBuilder: homeBuilder);
      break;
    case 2:
      destination = RutasInicioPage(homeBuilder: homeBuilder);
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