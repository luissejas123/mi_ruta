import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_state.dart';

/// Placeholder mínimo del modo chofer (RQ-68). El feature real de chofer
/// (gestión de viajes, ganancias, etc.) todavía no existe — esta pantalla
/// solo valida el cambio de rol y sirve de destino tras activarlo.
class ModoChoferPage extends StatelessWidget {
  const ModoChoferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = authState is AuthLoaded ? authState.user.uid : '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Modo Chofer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<DriverBloc, DriverState>(
        listener: (context, state) {
          if (state is DriverModeDeactivated) {
            Navigator.of(context).pop();
          }
          if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DriverLoading;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_taxi,
                    size: 72,
                    color: Color(0xFFFFC12F),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Estás en modo chofer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próximamente: gestión de viajes, pasajeros y ganancias.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<DriverBloc>()
                              .add(DeactivateDriverMode(userId)),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Volver a modo pasajero'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
