import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/test_widgets_screen.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';

void navigateBottomNav(BuildContext context, int index) {
  if (ModalRoute.of(context)?.isCurrent != true) {
    // ignore: avoid_print
    print('navigateBottomNav: current route is not active');
  }

  late Widget destination;

  switch (index) {
    case 0:
      destination = const MiRutaScreen();
      break;
    case 1:
      destination = const WalletPage();
      break;
    case 2:
      destination = const RutasInicioPage();
      break;
    case 3:
      destination = const TestWidgetsScreen();
      break;
    default:
      return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}
