import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';

/// Diálogo de confirmación de cierre de sesión, único en toda la app.
/// Antes cada pantalla (chofer, tickeador, perfil, selector super-admin)
/// tenía su propia copia casi idéntica de este método — y Admin cerraba
/// sesión sin preguntar nada, y el panel de dirigencia no tenía ni siquiera
/// la opción. Todas las pantallas con logout deben llamar a esta función.
void confirmLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro que deseas cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<AuthBloc>().add(const LogoutEvent());
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class LogoutButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LogoutButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Cerrar Sesion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
