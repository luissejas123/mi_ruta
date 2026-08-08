import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/trip_history_entry.dart';
import 'package:mi_ruta/features/user/domain/services/trip_history_service.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_history_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_history_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/trip_history_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/detalle_viaje_page.dart';

class HistorialViajesPage extends StatelessWidget {
  const HistorialViajesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthLoaded ? authState.user.uid : '';
        return TripHistoryBloc(service: getIt<TripHistoryService>())
          ..add(LoadTripHistory(userId));
      },
      child: const _HistorialView(),
    );
  }
}

class _HistorialView extends StatelessWidget {
  const _HistorialView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Historial de viajes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<TripHistoryBloc, TripHistoryState>(
        builder: (context, state) {
          if (state is TripHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is TripHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          if (state is TripHistoryLoaded) {
            if (state.trips.isEmpty) return const _EmptyState();
            return OrientationBuilder(
              builder: (context, orientation) => orientation == Orientation.landscape
                  ? _LandscapeList(trips: state.trips)
                  : _PortraitList(trips: state.trips),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin viajes registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus viajes aparecerán aquí\ncuando completes una ruta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitList extends StatelessWidget {
  final List<TripHistoryEntry> trips;
  const _PortraitList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: trips.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _TripCard(entry: trips[i]),
    );
  }
}

class _LandscapeList extends StatelessWidget {
  final List<TripHistoryEntry> trips;
  const _LandscapeList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemCount: trips.length,
      itemBuilder: (context, i) => _TripCard(entry: trips[i]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripHistoryEntry entry;
  const _TripCard({required this.entry});

  String _formatDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}. ${d.year}';
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleViajePage(entry: entry)),
      ),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC12F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.routeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.originName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.destinationName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.timer_outlined,
                      size: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatElapsed(entry.elapsed),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
      ),
    );
  }
}
