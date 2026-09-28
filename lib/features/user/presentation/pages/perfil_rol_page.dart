import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_conductor_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';

/// Enruta "Perfil" a la variante correcta según el rol — chofer ve
/// [PerfilConductorPage] (Figma 1.4 "Perfil (chofer)", antes sin página
/// propia), el resto de los roles sigue con el [PerfilPage] compartido de
/// siempre. [homeBuilder]/[walletBuilder]/[routesBuilder] se reenvían tal
/// cual a [PerfilPage] — ver `bottom_nav_router.dart` para por qué hacen
/// falta (si no, Billetera/Rutas dejan de ir a las pantallas del rol
/// correcto al volver desde Perfil).
class PerfilRolPage extends StatelessWidget {
  final WidgetBuilder? homeBuilder;
  final WidgetBuilder? walletBuilder;
  final WidgetBuilder? routesBuilder;

  const PerfilRolPage({
    super.key,
    this.homeBuilder,
    this.walletBuilder,
    this.routesBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final role = authState is AuthLoaded
        ? authState.user.role.trim().toLowerCase()
        : '';

    if (role == 'driver' || role == 'conductor') {
      return const PerfilConductorPage();
    }

    return PerfilPage(
      homeBuilder: homeBuilder,
      walletBuilder: walletBuilder,
      routesBuilder: routesBuilder,
    );
  }
}
