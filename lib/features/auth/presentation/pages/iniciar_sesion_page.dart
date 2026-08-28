import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/navigation/home_router.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/insertar_correo_page.dart';
import 'package:mi_ruta/features/auth/presentation/pages/register_page.dart';
import 'package:mi_ruta/features/auth/presentation/widgets/boton_amarillo.dart';

class IniciarSesionPage extends StatelessWidget {
  const IniciarSesionPage({super.key});

  void _onAuthLoaded(BuildContext context, AuthLoaded state) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homeScreenForRole(state.user)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Solo el "Modo prueba" llega a AuthLoaded desde esta pantalla —
          // el login/registro normal navega por su cuenta (InsertarCorreoPage).
          if (state is AuthLoaded) _onAuthLoaded(context, state);
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Center(
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
              const SizedBox(height: 40),
              const _ModoPruebaSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// TEMPORAL — Modo prueba para QA: entra a cada panel (pasajero/chofer/admin)
/// con Firebase Auth anónimo real + datos reales en Firestore, sin pedir
/// credenciales. Quitar esta sección cuando ya no se necesite para pruebas.
class _ModoPruebaSection extends StatelessWidget {
  const _ModoPruebaSection();

  void _entrar(BuildContext context, String role) {
    context.read<AuthBloc>().add(LoginAsDemoEvent(role: role));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'MODO PRUEBA (temporal)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => _entrar(context, 'user'),
              child: const Text('Pasajero'),
            ),
            OutlinedButton(
              onPressed: () => _entrar(context, 'driver'),
              child: const Text('Chofer'),
            ),
            OutlinedButton(
              onPressed: () => _entrar(context, 'admin'),
              child: const Text('Admin'),
            ),
          ],
        ),
      ],
    );
  }
}
