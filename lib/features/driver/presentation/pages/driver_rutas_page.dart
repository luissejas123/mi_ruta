import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_wallet_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/solicitud_chofer_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/driver_service_map.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

/// Tab "Rutas" del chofer (antes era literalmente la pantalla del pasajero,
/// `RutasInicioPage`, con su buscador "¿A dónde vamos?" — no tiene sentido
/// para un chofer). Muestra la ruta que el dirigente le asignó
/// (`users/{uid}.assigned_route_ref`, el mismo campo que ya usa el Home) en
/// un mapa grande, y un switch para "habilitar" esa ruta — que es el mismo
/// estado de servicio (`isOnDuty`) que el botón de Inicio, no un campo
/// nuevo: un chofer que no quiere trabajar esa ruta simplemente detiene
/// servicio.
class DriverRutasPage extends StatelessWidget {
  /// Mismo propósito que `DriverHomePage.roleOverride`: a qué perfil volver
  /// desde la pestaña "Inicio" — nulo cuando entra un chofer normal.
  final String? role;

  const DriverRutasPage({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DriverServiceBloc(service: getIt<DriverService>())
            ..add(LoadAssignedVehicle(uid)),
        ),
        BlocProvider(
          create: (_) => DriverOperationsBloc(service: getIt<DriverService>()),
        ),
      ],
      child: _DriverRutasView(role: role),
    );
  }
}

class _DriverRutasView extends StatelessWidget {
  final String? role;

  const _DriverRutasView({required this.role});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DriverServiceBloc, DriverServiceState>(
          listenWhen: (previous, current) =>
              current is DriverServiceLoaded && previous is! DriverServiceLoaded,
          listener: (context, state) {
            if (state is DriverServiceLoaded) {
              context.read<DriverOperationsBloc>().add(LoadDriverOperations(state.vehicle));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'Gestión de rutas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: BlocBuilder<DriverServiceBloc, DriverServiceState>(
          builder: (context, serviceState) {
            if (serviceState is DriverServiceLoading) {
              return const Center(child: CircularProgressIndicator(color: _amarillo));
            }
            if (serviceState is DriverServiceNoVehicle) {
              return const _NoVehicleMessage();
            }
            final vehicle = serviceState is DriverServiceLoaded
                ? serviceState.vehicle
                : serviceState is DriverServiceError
                    ? serviceState.vehicle
                    : null;
            if (vehicle == null) return const SizedBox.shrink();
            final isUpdating = serviceState is DriverServiceLoaded && serviceState.isUpdating;

            return BlocBuilder<DriverOperationsBloc, DriverOperationsState>(
              builder: (context, opsState) {
                final assignedRoute =
                    opsState is DriverOperationsLoaded ? opsState.assignedRoute : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DriverServiceMap(assignedRoute: assignedRoute, inService: vehicle.isOnDuty),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alt_route, color: _amarillo, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignedRoute != null
                                        ? '${assignedRoute.name} · Línea ${assignedRoute.ref}'
                                        : 'Sin ruta asignada',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    assignedRoute != null
                                        ? (vehicle.isOnDuty ? 'Ruta habilitada' : 'Ruta deshabilitada')
                                        : 'El dirigente aún no te asignó una línea.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (assignedRoute != null)
                              Switch(
                                value: vehicle.isOnDuty,
                                activeThumbColor: _amarillo,
                                onChanged: (!vehicle.isApproved || isUpdating)
                                    ? null
                                    : (value) => context.read<DriverServiceBloc>().add(
                                          value ? const StartService() : const StopService(),
                                        ),
                              ),
                          ],
                        ),
                      ),
                      if (!vehicle.isApproved) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Esta unidad debe estar aprobada antes de poder habilitar la ruta.',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                        ),
                      ],
                      if (opsState is DriverOperationsLoaded) ...[
                        const SizedBox(height: 16),
                        _NotifyStopSection(state: opsState),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 2,
          onTap: (index) => navigateBottomNav(
            context,
            index,
            homeBuilder: (_) => DriverHomePage(roleOverride: role),
            walletBuilder: (_) => DriverWalletPage(role: role),
            routesBuilder: (_) => DriverRutasPage(role: role),
          ),
        ),
      ),
    );
  }
}

/// El CTA "Registrar unidad" vivía en Inicio; el pedido explícito del
/// usuario fue moverlo aquí, al tab Rutas — Inicio ahora solo redirige.
class _NoVehicleMessage extends StatelessWidget {
  const _NoVehicleMessage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_filled_outlined,
                size: 48, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No tienes una unidad registrada',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Registra tu unidad con sus documentos antes de iniciar servicio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: uid.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SolicitudChoferPage(uid: uid, isAdditionalUnit: true),
                        ),
                      ),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Registrar unidad',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Notificar parada" — vivía suelto en Inicio; se reubica aquí porque es
/// una acción sobre la ruta en curso, igual que el switch de arriba.
class _NotifyStopSection extends StatefulWidget {
  final DriverOperationsLoaded state;

  const _NotifyStopSection({required this.state});

  @override
  State<_NotifyStopSection> createState() => _NotifyStopSectionState();
}

class _NotifyStopSectionState extends State<_NotifyStopSection> {
  final _stopCtrl = TextEditingController();

  @override
  void dispose() {
    _stopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 18, color: _amarillo),
              const SizedBox(width: 8),
              const Text('Notificar parada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _stopCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre de la parada',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () {
                      final stop = _stopCtrl.text.trim();
                      if (stop.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa el nombre de la parada.')),
                        );
                        return;
                      }
                      context.read<DriverOperationsBloc>().add(NotifyStop(stop));
                    },
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Avisar a pasajeros a bordo'),
            ),
          ),
          if (state.lastStopNotifiedCount != null) ...[
            const SizedBox(height: 8),
            Text(
              state.lastStopNotifiedCount! > 0
                  ? 'Se avisó a ${state.lastStopNotifiedCount} pasajero(s).'
                  : 'No hay pasajeros recientes a bordo de esta unidad para notificar.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
