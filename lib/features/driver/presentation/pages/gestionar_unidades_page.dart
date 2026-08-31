import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
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

const _amarillo = Color(0xFFFFC12F);

/// "Gestionar Unidades" (Figma "7.2 Gestión de unidades"). Versión simple
/// acordada: el modelo de datos hoy es 1 unidad por chofer
/// (`getVehicleForOwner` devuelve una sola), así que esta pantalla muestra
/// y edita esa unidad — es lo mismo que ya vivía suelto en Inicio, bajo su
/// propio nombre. Soporte real de varias unidades por chofer queda fuera
/// de alcance (sería su propio ticket, no una corrección menor).
class GestionarUnidadesPage extends StatelessWidget {
  const GestionarUnidadesPage({super.key});

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
      child: const _GestionarUnidadesView(),
    );
  }
}

class _GestionarUnidadesView extends StatelessWidget {
  const _GestionarUnidadesView();

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
          title: const Text('Gestionar Unidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        body: BlocBuilder<DriverServiceBloc, DriverServiceState>(
          builder: (context, serviceState) {
            if (serviceState is DriverServiceLoading) {
              return const Center(child: CircularProgressIndicator(color: _amarillo));
            }
            if (serviceState is DriverServiceNoVehicle) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tienes ninguna unidad registrada todavía.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
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
                final isBusy = opsState is DriverOperationsLoaded && opsState.isBusy;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UnitCard(
                        vehicle: vehicle,
                        isUpdating: isUpdating,
                        onToggleService: (!vehicle.isApproved || isUpdating)
                            ? null
                            : (value) => context.read<DriverServiceBloc>().add(
                                  value ? const StartService() : const StopService(),
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (opsState is DriverOperationsLoaded)
                        _EditVehicleForm(vehicle: vehicle, isBusy: isBusy),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final bool isUpdating;
  final ValueChanged<bool>? onToggleService;

  const _UnitCard({required this.vehicle, required this.isUpdating, required this.onToggleService});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: _amarillo, shape: BoxShape.circle),
            child: const Icon(Icons.directions_bus, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.brand} ${vehicle.model}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Placa ${vehicle.vehicleId} · Línea ${vehicle.lineNumber}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Switch(
            value: vehicle.isOnDuty,
            activeThumbColor: _amarillo,
            onChanged: onToggleService,
          ),
        ],
      ),
    );
  }
}

class _EditVehicleForm extends StatefulWidget {
  final VehicleEntity vehicle;
  final bool isBusy;

  const _EditVehicleForm({required this.vehicle, required this.isBusy});

  @override
  State<_EditVehicleForm> createState() => _EditVehicleFormState();
}

class _EditVehicleFormState extends State<_EditVehicleForm> {
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _internalNumberCtrl;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.vehicle.brand);
    _modelCtrl = TextEditingController(text: widget.vehicle.model);
    _colorCtrl = TextEditingController(text: widget.vehicle.color);
    _internalNumberCtrl = TextEditingController(text: widget.vehicle.internalNumber);
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _internalNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Datos de la unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
          _Field(label: 'Marca', controller: _brandCtrl),
          const SizedBox(height: 10),
          _Field(label: 'Modelo', controller: _modelCtrl),
          const SizedBox(height: 10),
          _Field(label: 'Color', controller: _colorCtrl),
          const SizedBox(height: 10),
          _Field(label: 'Número interno', controller: _internalNumberCtrl),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isBusy
                  ? null
                  : () => context.read<DriverOperationsBloc>().add(
                        UpdateVehicleInfo(
                          brand: _brandCtrl.text.trim(),
                          model: _modelCtrl.text.trim(),
                          color: _colorCtrl.text.trim(),
                          internalNumber: _internalNumberCtrl.text.trim(),
                        ),
                      ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _Field({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
