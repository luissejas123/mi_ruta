import 'package:flutter/material.dart';

// Tus imports existentes
import 'menu_title.dart';
import 'switch_title.dart';
import 'custom_bottom_nav.dart';

// Los nuevos imports
import 'profile_header.dart';
import 'logout_button.dart';

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
    return Scaffold(
      // Quitamos el AppBar para que se vea más como un perfil real de app
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
                onTap: () => print("Click en rutas"),
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
                onTap: () => print("Click en planificar"),
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
              const LogoutButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // 5. TU BARRA DE NAVEGACIÓN
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Marcamos el índice 3 (Perfil) como activo
        onTap: (index) => print("Click en pestaña $index"),
      ),
    );
  }
}