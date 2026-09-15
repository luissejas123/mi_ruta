import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';

class DriverPaymentPage extends StatefulWidget {
  const DriverPaymentPage({super.key});

  @override
  State<DriverPaymentPage> createState() => _DriverPaymentPageState();
}

class _DriverPaymentPageState extends State<DriverPaymentPage> {
  final _amountController = TextEditingController();
  late Future<VehicleEntity?> _vehicleFuture;
  String? _qrData;
  String? _error;
  bool _loading = false;
  bool _startingService = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _vehicleFuture = authState is AuthLoaded
        ? getIt<DriverService>().getAssignedVehicle(authState.user.uid)
        : Future.value(null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateCharge(VehicleEntity vehicle) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await getIt<DriverService>().generateTripCharge(
        vehicle: vehicle,
        amount: amount,
      );
      if (mounted) setState(() => _qrData = result['qrData'] as String);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startService(VehicleEntity vehicle) async {
    setState(() {
      _startingService = true;
      _error = null;
    });
    try {
      await getIt<DriverService>().startService(vehicle);
      if (mounted) {
        setState(
          () => _vehicleFuture = Future.value(
            VehicleEntity(
              vehicleId: vehicle.vehicleId,
              ownerUid: vehicle.ownerUid,
              lineNumber: vehicle.lineNumber,
              inService: true,
              serviceStartedAt: DateTime.now(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _startingService = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar viaje')),
      body: FutureBuilder<VehicleEntity?>(
        future: _vehicleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final vehicle = snapshot.data;
          if (vehicle == null) {
            return const Center(child: Text('No tienes un vehículo asignado.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Línea ${vehicle.lineNumber}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: vehicle.inService || _startingService
                    ? null
                    : () => _startService(vehicle),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  vehicle.inService
                      ? 'Jornada iniciada'
                      : _startingService
                      ? 'Registrando...'
                      : 'Iniciar jornada',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto del viaje',
                  prefixText: 'Bs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : () => _generateCharge(vehicle),
                icon: const Icon(Icons.qr_code_2),
                label: Text(_loading ? 'Generando...' : 'Generar QR de cobro'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_qrData != null) ...[
                const SizedBox(height: 28),
                Center(child: QrImageView(data: _qrData!, size: 240)),
                const SizedBox(height: 12),
                const Center(child: Text('El pasajero debe escanear este QR.')),
              ],
            ],
          );
        },
      ),
    );
  }
}