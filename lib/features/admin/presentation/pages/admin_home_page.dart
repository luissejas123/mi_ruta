import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/admin_active_vehicles_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';

/// Panel de entrada del admin: unidades de transporte actualmente activas.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    final isStaticDemo = uid == kStaticDemoAdminUid;

    return BlocProvider(
      create: (_) => getIt<AdminActiveVehiclesBloc>()
        ..add(isStaticDemo
            ? const WatchStaticDemoVehicles()
            : const WatchActiveVehicles()),
      child: _AdminHomeView(isStaticDemo: isStaticDemo),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  static const _amarillo = Color(0xFFFFC12F);
  final bool isStaticDemo;

  const _AdminHomeView({required this.isStaticDemo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades activas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AdminActiveVehiclesBloc, AdminActiveVehiclesState>(
              builder: (context, state) {
                if (state is AdminVehiclesLoading ||
                    state is AdminVehiclesInitial) {
                  return const Center(
                      child: CircularProgressIndicator(color: _amarillo));
                }
                if (state is AdminVehiclesError) {
                  return Center(child: Text(state.message));
                }
                if (state is AdminVehiclesLoaded) {
                  if (state.vehicles.isEmpty) {
                    return const Center(
                      child:
                          Text('Ninguna unidad está en servicio ahora mismo.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.vehicles.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final vehicle = state.vehicles[i];
                      final driver = state.driversByUid[vehicle.ownerUid];
                      return _VehicleTile(
                          vehicle: vehicle, driverName: driver?.fullName);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (isStaticDemo)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _BenefitAuthDemoSection(),
            ),
        ],
      ),
    );
  }
}

/// TEMPORAL — muestra cómo funcionaría la autorización de beneficios (RQ-47)
/// una vez que exista el rol real: aprobar/rechazar acá refleja el cambio en
/// el "movimiento" que ve el pasajero, tal como ya lo hace el código real
/// (`BenefitRequestDatasource._syncMirroredTransactionStatus`). Es puramente
/// visual — no toca Firebase ni Firestore. Quitar cuando el rol exista.
class _BenefitAuthDemoSection extends StatefulWidget {
  const _BenefitAuthDemoSection();

  @override
  State<_BenefitAuthDemoSection> createState() =>
      _BenefitAuthDemoSectionState();
}

class _BenefitAuthDemoSectionState extends State<_BenefitAuthDemoSection> {
  String _status = 'pending';

  String get _statusLabel => switch (_status) {
        'approved' => 'Aprobada',
        'rejected' => 'Rechazada',
        _ => 'En revisión',
      };

  Color get _statusColor => switch (_status) {
        'approved' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTORIZACIÓN DE BENEFICIOS (demo — sin rol real aún)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.card_membership,
                      color: Color(0xFFFFC12F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solicitud de beneficio — Universitario',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Demo (Chofer)',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _status = 'rejected'),
                        style:
                            OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _status = 'approved'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Aprobar'),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _status = 'pending'),
                    child: const Text('Reiniciar demo'),
                  ),
                ),
              const Divider(height: 24),
              Text(
                'Así se vería en "Movimientos" del pasajero:',
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Solicitud de beneficio · $_statusLabel',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final VehicleEntity vehicle;
  final String? driverName;

  const _VehicleTile({required this.vehicle, this.driverName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Línea ${vehicle.lineNumber}  •  ${vehicle.vehicleId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  driverName ?? 'Chofer sin datos',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                Text(
                  '${vehicle.vehicleType} · ${vehicle.passengerCapacity} pasajeros',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'En servicio',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
