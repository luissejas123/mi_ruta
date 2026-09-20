import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/utils/distance_utils.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/user/domain/usecases/get_current_location_usecase.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';

const _amarillo = Color(0xFFFFC12F);

/// Resultado de un abordaje confirmado — lo consume `RutaNavegacionPage`
/// para saltarse la fase de "escanear para abordar" (ya se hizo acá) y
/// habilitar "Aviso de bajada" desde el inicio.
typedef BoardingConfirmationResult =
    ({String tripId, String driverId, String routeRef});

/// Confirma abordaje real antes de navegar (Bloque 2, paso 3, rediseño
/// 2026-09-14) — antes, elegir una línea en `RutaLineaPage` contaba como
/// "ya estoy en el vehículo" sin verificar nada. Ahora hay que escanear el
/// QR fijo de la unidad (`UnitQrPage`) o escribir su placa; si el GPS del
/// pasajero está lejos del trazado real de la línea de esa unidad, se
/// pregunta si confirma igual y, confirme o no, queda registrado como
/// `route_mismatch` (observación silenciosa para chofer/dirigente/admin).
class ConfirmarAbordajePage extends StatefulWidget {
  final String plannedRouteRef;
  final String plannedRouteName;

  const ConfirmarAbordajePage({
    super.key,
    required this.plannedRouteRef,
    required this.plannedRouteName,
  });

  @override
  State<ConfirmarAbordajePage> createState() => _ConfirmarAbordajePageState();
}

class _ConfirmarAbordajePageState extends State<ConfirmarAbordajePage> {
  static const _maxDistanceFromRouteMeters = 150.0;

  final _plateController = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    if (_confirming) return;
    final qrCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(title: 'Escanea el QR de la unidad'),
      ),
    );
    if (qrCode == null || qrCode.isEmpty || !mounted) return;

    final parts = qrCode.split('|');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ese QR no es el de una unidad — escanea el que está pegado en el vehículo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final ownerUid = parts[0];
    final vehicleId = parts[1];

    setState(() => _confirming = true);
    try {
      final vehicle = await getIt<DriverService>().getAssignedVehicle(ownerUid);
      if (vehicle == null || vehicle.vehicleId != vehicleId) {
        throw Exception('No se pudo verificar la unidad escaneada.');
      }
      await _confirmWithVehicle(vehicle);
    } catch (e) {
      _showError('No se pudo confirmar el abordaje: $e');
    }
  }

  Future<void> _confirmWithPlate() async {
    if (_confirming) return;
    final plate = _plateController.text.trim();
    if (plate.isEmpty) {
      _showError('Ingresa la placa de la unidad.');
      return;
    }
    setState(() => _confirming = true);
    try {
      final vehicle = await getIt<DriverService>().getVehicleByPlate(plate);
      if (vehicle == null) {
        throw Exception('No se encontró una unidad con esa placa.');
      }
      await _confirmWithVehicle(vehicle);
    } catch (e) {
      _showError('No se pudo confirmar el abordaje: $e');
    }
  }

  Future<void> _confirmWithVehicle(VehicleEntity vehicle) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) {
      _showError('Sesión no válida.');
      return;
    }

    final driverService = getIt<DriverService>();
    final route = await driverService.getAssignedRoute(vehicle);
    final polyline = route?.polyline;

    var routeMismatch = false;
    if (polyline != null && polyline.length >= 2) {
      final positionResult = await getIt<GetCurrentLocationUseCase>()();
      routeMismatch = positionResult.fold(
        // Sin GPS no se puede evaluar — no se bloquea el abordaje por esto.
        (_) => false,
        (position) {
          final points = polyline
              .map((p) => LatLng(p['lat']!, p['lng']!))
              .toList();
          final distance = DistanceUtils.distanceToPolylineMeters(position, points);
          return distance > _maxDistanceFromRouteMeters;
        },
      );
    }

    if (routeMismatch) {
      if (!mounted) return;
      final confirmAnyway = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fuera de la ruta de esta unidad'),
          content: const Text(
            'No pareces estar sobre el recorrido real de la línea de esta '
            'unidad. ¿Confirmas el abordaje igual?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
              child: const Text('Confirmar igual', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      if (confirmAnyway != true) {
        setState(() => _confirming = false);
        return;
      }
    }
    if (!mounted) return;

    try {
      final tripId = await driverService.createBoardingTrip(
        vehicle: vehicle,
        passengerId: authState.user.uid,
        route: route,
        routeMismatch: routeMismatch,
      );
      if (!mounted) return;
      Navigator.pop<BoardingConfirmationResult>(context, (
        tripId: tripId,
        driverId: vehicle.ownerUid,
        routeRef: route?.ref ?? vehicle.lineNumber,
      ));
    } catch (e) {
      _showError('No se pudo confirmar el abordaje: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _confirming = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar abordaje', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vas a abordar Línea ${widget.plannedRouteRef} · ${widget.plannedRouteName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea el QR fijo de la unidad o escribe su placa para confirmar que abordaste.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _confirming ? null : _scanQr,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
              label: const Text('Escanear QR de la unidad', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarillo,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('O', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              enabled: !_confirming,
              decoration: InputDecoration(
                hintText: 'Placa de la unidad (ej: 2341-ABC)',
                prefixIcon: const Icon(Icons.directions_bus_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _confirming ? null : _confirmWithPlate,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _amarillo, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _confirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _amarillo),
                    )
                  : const Text('Confirmar con placa', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
