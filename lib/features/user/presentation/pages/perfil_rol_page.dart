import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';

/// Antes enrutaba el chofer a un `PerfilConductorPage` aparte (Figma 1.4)
/// con solo 4 opciones estáticas y sin `homeBuilder`/`walletBuilder`/
/// `routesBuilder` en su propio pie de navegación — tocar Inicio/Billetera/
/// Rutas desde ahí siempre caía a las pantallas del pasajero sin importar el
/// rol real (bug reportado). `PerfilPage` ya maneja bien el rol chofer
/// (secciones "Ruta asignada"/"Gestionar Unidades", historial del
/// conductor, etc.) igual que ya hace con presidente/admin/tickeador — así
/// que ahora todos los roles pasan por el mismo `PerfilPage`, sin una
/// variante aparte y desactualizada solo para chofer. Este archivo queda
/// como un simple reenvío de [homeBuilder]/[walletBuilder]/[routesBuilder]
/// para no tener que tocar `bottom_nav_router.dart`.
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
    return PerfilPage(
      homeBuilder: homeBuilder,
      walletBuilder: walletBuilder,
      routesBuilder: routesBuilder,
    );
  }
}
