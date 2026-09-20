import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_state.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/trip_history_item.dart';

const _amarillo = Color(0xFFFFC12F);

class DriverTripHistoryPage extends StatelessWidget {
  final String driverId;

  const DriverTripHistoryPage({Key? key, required this.driverId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DriverTripHistoryBloc(driverService: getIt())..add(LoadTripHistory(driverId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Viajes'),
          centerTitle: true,
        ),
        body: BlocBuilder<DriverTripHistoryBloc, DriverTripHistoryState>(
          builder: (context, state) {
            if (state is TripHistoryInitial || state is TripHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TripHistoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar el historial: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DriverTripHistoryBloc>().add(LoadTripHistory(driverId));
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is TripHistoryLoaded) {
              if (state.trips.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay viajes registrados',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _TripsSummaryCard(trips: state.trips),
                  const SizedBox(height: 12),
                  ...state.trips.map((trip) => TripHistoryItem(trip: trip)),
                ],
              );
            }

            return const Center(child: Text('Estado no reconocido'));
          },
        ),
      ),
    );
  }
}

/// "6.2.1/6.2.2 Historial de viajes — Resumen" (Figma): total acumulado +
/// viajes realizados + botón para generar/compartir el PDF que ya existía
/// (`DriverService.exportHistoryPdf`, antes solo alcanzable desde Inicio).
/// No se inventan campos que la app no calcula de verdad ("puntos ganados",
/// distancia/duración del viaje) — solo lo que `DriverTripEntity` sí trae.
class _TripsSummaryCard extends StatefulWidget {
  final List<DriverTripEntity> trips;

  const _TripsSummaryCard({required this.trips});

  @override
  State<_TripsSummaryCard> createState() => _TripsSummaryCardState();
}

class _TripsSummaryCardState extends State<_TripsSummaryCard> {
  bool _downloading = false;

  Future<void> _download(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final driverName = authState is AuthLoaded ? authState.user.fullName : 'Chofer';
    setState(() => _downloading = true);
    try {
      final service = getIt<DriverService>();
      final file = await service.exportHistoryPdf(
        driverName: driverName.isNotEmpty ? driverName : 'Chofer',
        trips: widget.trips,
        income: const [],
      );
      await service.shareFile(file, subject: 'Historial de viajes - Mi Ruta');
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const _DownloadCompletePage()));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar el historial: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = widget.trips.where((t) => t.isPaid).toList();
    final total = paid.fold<double>(0, (sum, t) => sum + (t.paymentAmount ?? 0));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _amarillo, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de viajes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          const SizedBox(height: 10),
          Text('Total acumulado: Bs ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          const SizedBox(height: 4),
          Text('Viajes realizados: ${widget.trips.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _downloading ? null : () => _download(context),
              icon: _downloading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              label: const Text('Descargar'),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// "6.2.3 Descarga Completada" (Figma).
class _DownloadCompletePage extends StatelessWidget {
  const _DownloadCompletePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Descarga Realizada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Su historial de viaje ha sido compartido exitosamente!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}