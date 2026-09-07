import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_panel_page.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_approval_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_wallet_page.dart';
import 'package:mi_ruta/features/presidente/presentation/pages/presidente_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/driver_service_map.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart' show confirmLogout;
import 'package:mi_ruta/features/driver/presentation/pages/rate_passenger_page.dart';

class DriverHomePage extends StatelessWidget {
  /// Fuerza el rol usado para decidir si se muestran las secciones de
  /// dirigente, sin depender del `role` real de la cuenta. Solo la usa el
  /// selector de perfiles de la cuenta super-admin.
  final String? roleOverride;

  const DriverHomePage({super.key, this.roleOverride});

  static const _amarillo = Color(0xFFFFC12F);

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final fullName = authState is AuthLoaded ? authState.user.fullName : '';
    final role = roleOverride ?? (authState is AuthLoaded ? authState.user.role : '');

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
      child: _DriverHomeView(fullName: fullName, role: role),
    );
  }
}

class _DriverHomeView extends StatelessWidget {
  final String fullName;
  final String role;

  const _DriverHomeView({required this.fullName, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSupervisor = role == 'presidente';
    final authState = context.read<AuthBloc>().state;
    final driverUid = authState is AuthLoaded ? authState.user.uid : '';

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
        // "3.3 Notificación Temporal": aviso breve tras iniciar/detener servicio.
        BlocListener<DriverServiceBloc, DriverServiceState>(
          listenWhen: (previous, current) =>
              previous is DriverServiceLoaded &&
              previous.isUpdating &&
              current is DriverServiceLoaded &&
              !current.isUpdating,
          listener: (context, state) {
            final vehicle = (state as DriverServiceLoaded).vehicle;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                backgroundColor: vehicle.isOnDuty ? Colors.green.shade700 : Colors.grey.shade800,
                content: Text(
                  vehicle.isOnDuty ? 'Estado del servicio cambió a: Activo' : 'Servicio detenido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        // "¡Ruta Asignada!" — el dirigente le asigna línea a este chofer
        // mientras tiene la app abierta (o la app termina de cargarla).
        if (!isSupervisor)
          BlocListener<DriverOperationsBloc, DriverOperationsState>(
            listenWhen: (previous, current) =>
                previous is DriverOperationsLoaded &&
                previous.assignedRoute == null &&
                current is DriverOperationsLoaded &&
                current.assignedRoute != null,
            listener: (context, state) {
              final route = (state as DriverOperationsLoaded).assignedRoute!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.green.shade700,
                  content: Text(
                    '¡Ruta Asignada! ${route.name} · Línea ${route.ref}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        // Pago de viaje recibido: aviso + flujo de calificación al pasajero
        // ("5.4 Calificación del pasajero", Figma).
        if (!isSupervisor)
          BlocListener<DriverOperationsBloc, DriverOperationsState>(
            listenWhen: (previous, current) {
              if (previous is DriverOperationsLoaded && current is DriverOperationsLoaded) {
                return current.lastPaymentReceivedAmount != previous.lastPaymentReceivedAmount &&
                    current.lastPaymentReceivedAmount != null;
              }
              return false;
            },
            listener: (context, state) {
              final loaded = state as DriverOperationsLoaded;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('¡Pago de Bs. ${loaded.lastPaymentReceivedAmount!.toStringAsFixed(2)} recibido!'),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              final passengerId = loaded.lastPaymentReceivedPassengerId;
              if (passengerId != null && passengerId.isNotEmpty && driverUid.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatePassengerPage(
                      tripId: loaded.lastPaymentReceivedTripId ?? '',
                      driverUid: driverUid,
                      passengerId: passengerId,
                    ),
                  ),
                );
              }
            },
          ),
      ],
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            isSupervisor ? 'Panel del Dirigente' : 'Modo Chofer',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            const SwitchProfileButton(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => confirmLogout(context),
            ),
          ],
        ),
        // "3.1/3.2 Inicio del chofer" (Figma): solo mapa + botón de
        // iniciar/detener servicio. Todo lo demás que antes vivía suelto
        // aquí (datos de unidad, cobro por QR, notificar parada,
        // rendimiento, historiales, descarga de PDF) ya tiene su propia
        // pantalla — Gestionar Unidades, Billetera y Rutas — así que no se
        // duplica en Inicio.
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${fullName.isNotEmpty ? fullName : 'chofer'} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isSupervisor ? 'Dirigente' : 'Chofer',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              // "Registrar unidad"/estado de servicio es exclusivo del perfil
              // de chofer — el dirigente entra aquí solo para las tarjetas de
              // supervisión de abajo, nunca para gestionar una unidad propia.
              if (!isSupervisor) ...[
                const SizedBox(height: 24),
                const _VehicleServiceSection(),
              ],
              if (isSupervisor) ...[
                const SizedBox(height: 24),
                _SupervisorSection(),
                const SizedBox(height: 12),
                _PresidentePanelSection(),
              ],
            ],
          ),
        ),
        // El dirigente (isSupervisor) no tiene Billetera y su "Rutas" es
        // "Control de rutas en vivo" (PresidenteRutasPage), no la pantalla
        // de ruta asignada del chofer — son perfiles distintos aunque
        // entren por la misma pantalla de Inicio.
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 0,
          tabs: isSupervisor ? const [0, 2, 3] : const [0, 1, 2, 3],
          onTap: (index) => navigateBottomNav(
            context,
            index,
            homeBuilder: (_) => DriverHomePage(roleOverride: role),
            walletBuilder: isSupervisor ? null : (_) => DriverWalletPage(role: role),
            routesBuilder: isSupervisor
                ? (_) => const PresidenteRutasPage()
                : (_) => DriverRutasPage(role: role),
          ),
        ),
      ),
    );
  }
}

class _SupervisorSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DriverApprovalPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DriverHomePage._amarillo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.how_to_reg_outlined, color: Colors.black, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Aprobar o bloquear choferes',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PresidentePanelSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PresidentePanelPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DriverHomePage._amarillo, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, color: colorScheme.onSurface, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Panel de dirigencia (rutas y reportes)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

class _VehicleServiceSection extends StatelessWidget {
  const _VehicleServiceSection();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverServiceBloc, DriverServiceState>(
      listenWhen: (previous, current) => current is DriverServiceError,
      listener: (context, state) {
        if (state is DriverServiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DriverServiceLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: DriverHomePage._amarillo),
            ),
          );
        }
        if (state is DriverServiceNoVehicle) {
          return _NoVehicleCard();
        }
        final vehicle = state is DriverServiceLoaded
            ? state.vehicle
            : state is DriverServiceError
                ? state.vehicle
                : null;
        final isUpdating = state is DriverServiceLoaded && state.isUpdating;
        if (vehicle == null) return const SizedBox.shrink();
        final opsState = context.watch<DriverOperationsBloc>().state;
        final assignedRoute = opsState is DriverOperationsLoaded ? opsState.assignedRoute : null;
        return _VehicleCard(vehicle: vehicle, isUpdating: isUpdating, assignedRoute: assignedRoute);
      },
    );
  }
}

/// Ya no ofrece el botón "Registrar unidad" aquí — el pedido explícito fue
/// mover ese mensaje al tab Rutas, donde `DriverRutasPage` sí lo muestra
/// junto al CTA real. Inicio solo indica que hay que ir allá.
class _NoVehicleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_bus_filled_outlined,
              size: 40, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'No tienes una unidad registrada',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Ve a la pestaña Rutas para registrar tu unidad antes de iniciar servicio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final bool isUpdating;
  final RouteEntity? assignedRoute;

  const _VehicleCard({
    required this.vehicle,
    required this.isUpdating,
    this.assignedRoute,
  });

  @override
  Widget build(BuildContext context) {
    final canOperate = vehicle.isApproved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sin la card de datos de la unidad (placa/marca/estado): el mapa en
        // vivo con la posición del chofer + la ruta asignada es lo que
        // importa acá, y usa el espacio que antes ocupaba la card. El
        // status de la unidad ya se ve en el color del marcador del mapa
        // (verde/naranja) y en el propio botón de abajo.
        DriverServiceMap(
          assignedRoute: assignedRoute,
          inService: vehicle.isOnDuty,
          height: 340,
        ),
        if (!canOperate) ...[
          const SizedBox(height: 10),
          Text(
            'Esta unidad debe estar aprobada antes de poder iniciar servicio.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: !canOperate || isUpdating
                ? null
                : () => context.read<DriverServiceBloc>().add(
                      vehicle.isOnDuty ? const StopService() : const StartService(),
                    ),
            icon: isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Icon(
                    vehicle.isOnDuty ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                    color: Colors.black,
                  ),
            label: Text(
              vehicle.isOnDuty ? 'Finalizar servicio' : 'Iniciar servicio',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vehicle.isOnDuty ? Colors.grey.shade300 : DriverHomePage._amarillo,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
