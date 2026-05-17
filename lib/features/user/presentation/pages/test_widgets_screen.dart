import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart';
import 'package:mi_ruta/features/user/presentation/widgets/menu_title.dart';
import 'package:mi_ruta/features/user/presentation/widgets/profile_header.dart';
import 'package:mi_ruta/features/user/presentation/widgets/switch_title.dart';

class TestWidgetsScreen extends StatefulWidget {
  const TestWidgetsScreen({super.key});

  @override
  State<TestWidgetsScreen> createState() => _TestWidgetsScreenState();
}

class _TestWidgetsScreenState extends State<TestWidgetsScreen> {
  bool valorOscuro = false;
  bool modoConductor = false; // Agregado para el segundo switch de tu imagen

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
            (_) => false,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. EL ENCABEZADO (Foto y Nombre)
                const ProfileHeader(),

                const SizedBox(height: 10),

                // 2. TUS WIDGETS DE MENÚ
                MenuTile(
                  title: "Rutas frecuentes",
                  icon: Icons.map_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RutasInicioPage()),
                    );
                  },
                ),
                MenuTile(
                  title: "Historial de Viajes",
                  icon: Icons.history,
                  onTap: () => print("Click en historial"),
                ),
                MenuTile(
                  title: "Notificaciones",
                  icon: Icons.notifications_none,
                  onTap: () => print("Click en notificaciones"),
                ),
                MenuTile(
                  title: "Planificar ruta",
                  icon: Icons.map,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RutasInicioPage()),
                    );
                  },
                ),

                // 3. TUS SWITCHES
                SwitchTile(
                  title: "Modo Oscuro",
                  icon: Icons.dark_mode_outlined,
                  value: valorOscuro,
                  onChanged: (nuevoValor) {
                    setState(() => valorOscuro = nuevoValor);
                  },
                ),
                SwitchTile(
                  title: "Modo conductor",
                  icon: Icons.directions_car_filled_outlined,
                  value: modoConductor,
                  onChanged: (nuevoValor) {
                    setState(() => modoConductor = nuevoValor);
                  },
                ),

                const SizedBox(height: 30),

                // 4. EL BOTÓN DE CIERRE
                LogoutButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const LogoutEvent());
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // 5. TU BARRA DE NAVEGACIÓN
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 3,
          onTap: (index) => navigateBottomNav(context, index),
        ),
      ),
    );
  }
}
