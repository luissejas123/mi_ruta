import 'package:flutter/material.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';

class AdminBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavigationBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    late Widget destination;

    switch (index) {
      case 0:
        destination = const AdminHomePage();
        break;
      case 1:
        destination = const WalletPage();
        break;
      case 2:
        destination = const RutasInicioPage();
        break;
      case 3:
        destination = const PerfilPage();
        break;
      default:
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navigate(context, index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Billetera'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rutas'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
