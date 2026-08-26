import 'package:flutter/material.dart';
import 'package:mi_ruta/features/admin/presentation/pages/admin_privileges_page.dart';
import 'package:mi_ruta/features/auth/domain/entities/auth_entity.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_home_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/mi_ruta_screen.dart';

/// Decide la pantalla de inicio segun el rol del usuario autenticado.
/// Usar siempre que se navegue a la pantalla principal tras login/registro,
/// para no duplicar el criterio de enrutamiento por rol.
Widget homeScreenForRole(AuthEntity user) {
  if (user.role == 'admin') return const AdminPrivilegesPage();
  if (user.role == 'presidente') return const PresidenteHomePage();
  return const MiRutaScreen();
}
