import 'package:flutter/material.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_home_page.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_home_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';

/// Decide la pantalla de inicio segun el rol del usuario autenticado.
/// Usar siempre que se navegue a la pantalla principal tras login/registro,
/// para no duplicar el criterio de enrutamiento por rol.
Widget homeScreenForRole(AuthEntity user) {
  switch (user.role) {
    case 'admin':
      return const AdminHomePage();
    case 'presidente':
      return const PresidentePanelPage();
    case 'driver':
      return const DriverHomePage();
    case 'tickeador':
      return const TickeadorHomePage();
    default:
      return const MiRutaScreen();
  }
}
