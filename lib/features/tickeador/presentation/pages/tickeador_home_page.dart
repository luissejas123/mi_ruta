import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_bloc.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_event.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

class TickeadorHomePage extends StatelessWidget {
  const TickeadorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final fullName = authState is AuthLoaded ? authState.user.fullName : '';

    return BlocProvider(
      create: (_) => TickeadorBloc(service: getIt<TickeadorService>())
        ..add(LoadVerificationHistory(uid)),
      child: _TickeadorHomeView(uid: uid, fullName: fullName),
    );
  }
}

class _TickeadorHomeView extends StatelessWidget {
  final String uid;
  final String fullName;

  const _TickeadorHomeView({required this.uid, required this.fullName});

  void _cerrarSesion(BuildContext context) {
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
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage(title: 'Validar ticket')),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      context.read<TickeadorBloc>().add(ValidateTripQr(result, uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Modo Tickeador',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          const SwitchProfileButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${fullName.isNotEmpty ? fullName : 'tickeador'} 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            BlocConsumer<TickeadorBloc, TickeadorState>(
              listenWhen: (previous, current) => current is TickeadorError,
              listener: (context, state) {
                if (state is TickeadorError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red.shade700),
                  );
                }
              },
              builder: (context, state) {
                final isValidating = state is TickeadorLoaded && state.isValidating;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isValidating ? null : () => _scan(context),
                        icon: isValidating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.qr_code_scanner, color: Colors.black),
                        label: const Text(
                          'Escanear ticket de pasajero',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (state is TickeadorLoaded && state.lastValidatedTrip != null) ...[
                      const SizedBox(height: 16),
                      _ValidationResultCard(trip: state.lastValidatedTrip!),
                    ],
                    if (state is TickeadorLoaded && state.lastValidationError != null) ...[
                      const SizedBox(height: 16),
                      _ValidationErrorCard(message: state.lastValidationError!),
                    ],
                    const SizedBox(height: 24),
                    const Text('Historial de validaciones',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    if (state is TickeadorLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: _amarillo),
                        ),
                      )
                    else if (state is TickeadorLoaded)
                      state.history.isEmpty
                          ? Text(
                              'Todavía no validaste ningún ticket.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            )
                          : Column(
                              children: state.history.map((t) => _HistoryTile(trip: t)).toList(),
                            ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => navigateBottomNav(
          context,
          index,
          homeBuilder: (_) => const TickeadorHomePage(),
        ),
      ),
    );
  }
}

class _ValidationResultCard extends StatelessWidget {
  final DriverTripEntity trip;

  const _ValidationResultCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pago verificado', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${trip.routeName.isNotEmpty ? trip.routeName : trip.routeRef} · '
                  'Bs. ${(trip.paymentAmount ?? trip.baseFare).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationErrorCard extends StatelessWidget {
  final String message;

  const _ValidationErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No verificado', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(message, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final DriverTripEntity trip;

  const _HistoryTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              trip.routeName.isNotEmpty ? trip.routeName : trip.routeRef,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Bs. ${(trip.paymentAmount ?? trip.baseFare).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
