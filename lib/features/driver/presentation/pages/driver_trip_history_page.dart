import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/driver/domain/entities/driver_trip_entity.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_trip_history_state.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/trip_history_item.dart';

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

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.trips.length,
                itemBuilder: (context, index) {
                  final trip = state.trips[index];
                  return TripHistoryItem(trip: trip);
                },
              );
            }

            return const Center(child: Text('Estado no reconocido'));
          },
        ),
      ),
    );
  }
}