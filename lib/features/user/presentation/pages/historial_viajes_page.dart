import 'dart:io';
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
import 'package:mi_ruta/features/user/presentation/pages/download_success_screen.dart';

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

  /// Descarga el historial completo en PDF (ya implementado en
  /// `TripHistoryService` — antes vivía en este mismo archivo pero sin
  /// ningún botón que lo llamara). No confundir con "Descargar constancia
  /// de viaje" de `DetalleViajePage`, que es el comprobante de un viaje
  /// individual — este es el resumen completo.
  Future<void> _downloadFullHistory(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para descargar')),
      );
      return;
    }

    final savedFilePath = await getIt<TripHistoryService>()
        .downloadDriverTripHistory(authState.user.uid);

    if (savedFilePath.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay historial para descargar')),
      );
      return;
    }

    final savedFile = File(savedFilePath);
    if (!savedFile.existsSync()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el PDF del historial')),
      );
      return;
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DownloadSuccessScreen(
          fileName: savedFile.uri.pathSegments.last,
          filePath: savedFile.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
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
            return TripHistoryListWidget(
              trips: state.trips,
              onDownloadFullHistory: () => _downloadFullHistory(context),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class TripHistoryListWidget extends StatefulWidget {
  final List<TripHistoryEntry> trips;
  final VoidCallback? onDownloadFullHistory;

  const TripHistoryListWidget({
    super.key,
    required this.trips,
    this.onDownloadFullHistory,
  });

  @override
  State<TripHistoryListWidget> createState() => _TripHistoryListWidgetState();
}

class _TripHistoryListWidgetState extends State<TripHistoryListWidget> {
  static const _filterOptions = ['Hoy', 'Semanal', 'Mensual', 'Todos'];
  String _selectedFilter = 'Todos';

  List<TripHistoryEntry> get _filteredTrips {
    final sortedTrips = [...widget.trips]
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_selectedFilter == 'Todos') return sortedTrips;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return sortedTrips.where((trip) {
      final tripDay = DateTime(trip.date.year, trip.date.month, trip.date.day);
      switch (_selectedFilter) {
        case 'Hoy':
          return tripDay == today;
        case 'Semanal':
          final weekAgo = today.subtract(const Duration(days: 7));
          return !tripDay.isBefore(weekAgo) && !tripDay.isAfter(today);
        case 'Mensual':
          return trip.date.year == now.year && trip.date.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filteredTrips;

    return Container(
      color: const Color(0xFFD9D9D9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MOVIMIENTOS',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.onDownloadFullHistory != null)
                    IconButton(
                      tooltip: 'Descargar historial completo',
                      icon: const Icon(Icons.download_outlined, color: Colors.black87),
                      onPressed: widget.onDownloadFullHistory,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filterOptions[index];
                    final selected = filter == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFFFC12F) : const Color(0xFFFFD14D),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          filter,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (filteredTrips.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No hay viajes registrados',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OrientationBuilder(
                    builder: (context, orientation) {
                      return orientation == Orientation.portrait
                          ? _PortraitList(trips: filteredTrips)
                          : _LandscapeList(trips: filteredTrips);
                    },
                  ),
                ),
            ],
          ),
        ),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin viajes registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus viajes aparecerán aquí\ncuando completes una ruta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta rica con tap-to-detail — antes vivía en este archivo sin que
/// nadie la usara (reemplazada en algún momento por una fila plana sin
/// interacción). Recuperada: ahora es la única forma de renderizar un viaje
/// en esta pantalla, en vertical (lista) y horizontal (cuadrícula).
class _PortraitList extends StatelessWidget {
  final List<TripHistoryEntry> trips;
  const _PortraitList({required this.trips});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.only(bottom: 16),
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
              child: const Icon(
                Icons.directions_bus,
                color: Colors.black,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.routeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                      const SizedBox(width: 10),
                      Text(
                        '- Bs ${entry.farePaid > 0 ? entry.farePaid.toStringAsFixed(2) : '0.00'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE0A209),
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
