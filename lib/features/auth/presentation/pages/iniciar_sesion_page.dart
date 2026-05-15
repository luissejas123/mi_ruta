import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/pages/insertar_correo_page.dart';
import 'package:mi_ruta/features/auth/presentation/pages/register_page.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/boton_amarillo.dart';

class IniciarSesionPage extends StatelessWidget {
  const IniciarSesionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MiRuta',
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu ruta, tu viaje,\ntu pago.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 50),
            BotonAmarillo(
              texto: 'Iniciar sesión',
              alPresionar: () {
                final authBloc = context.read<AuthBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: authBloc,
                      child: const InsertarCorreoPage(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            BotonAmarillo(
              texto: 'Registrarte',
              alPresionar: () {
                final authBloc = context.read<AuthBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: authBloc,
                      child: const RegisterPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
