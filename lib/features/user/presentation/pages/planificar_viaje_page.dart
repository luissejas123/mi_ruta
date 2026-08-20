import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/planned_trip.dart';
import 'package:mi_ruta/features/routes/domain/services/planned_trip_service.dart';
import 'package:mi_ruta/features/routes/presentation/bloc/trip_planner_bloc.dart';
import 'package:mi_ruta/features/routes/presentation/bloc/trip_planner_event.dart';
import 'package:mi_ruta/features/routes/presentation/bloc/trip_planner_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_location_picker_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/map_search_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/plan_detalle_page.dart';

class PlanificarViajePage extends StatelessWidget {
  final PlannedTrip? tripToReschedule;
  const PlanificarViajePage({super.key, this.tripToReschedule});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TripPlannerBloc(service: getIt<PlannedTripService>()),
      child: _PlanificarViajeView(tripToReschedule: tripToReschedule),
    );
  }
}

class _PlanificarViajeView extends StatefulWidget {
  final PlannedTrip? tripToReschedule;
  const _PlanificarViajeView({this.tripToReschedule});
  @override
  State<_PlanificarViajeView> createState() => _PlanificarViajeViewState();
}

class _PlanificarViajeViewState extends State<_PlanificarViajeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  PlaceResult? _origin;
  PlaceResult? _destination;
  LatLng? _userLocation;

  String get _userId {
    final s = context.read<AuthBloc>().state;
    return s is AuthLoaded ? s.user.uid : '';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1) {
        context.read<TripPlannerBloc>().add(LoadMyPlans(_userId));
      }
    });
    final reschedule = widget.tripToReschedule;
    if (reschedule != null) {
      _origin = PlaceResult(
          latLng: reschedule.originLatLng, name: reschedule.originName);
      _destination = PlaceResult(
          latLng: reschedule.destinationLatLng,
          name: reschedule.destinationName);
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<String?> _showMethodSheet(String title) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFC12F),
                    child: Icon(Icons.search, color: Colors.black, size: 20),
                  ),
                  title: const Text('Buscar por nombre o dirección'),
                  subtitle: const Text('Escribe para encontrar un lugar'),
                  onTap: () => Navigator.pop(ctx, 'search'),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFC12F),
                    child: Icon(Icons.map_outlined,
                        color: Colors.black, size: 20),
                  ),
                  title: const Text('Seleccionar en el mapa'),
                  subtitle: const Text('Mueve el mapa y confirma el punto'),
                  onTap: () => Navigator.pop(ctx, 'map'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickOrigin() async {
    final method = await _showMethodSheet('Seleccionar origen');
    if (!mounted || method == null) return;
    PlaceResult? result;
    if (method == 'search') {
      result = await Navigator.push<PlaceResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MapSearchPage(
            currentLocation: _userLocation,
            searchMode: SearchMode.origin,
          ),
        ),
      );
    } else {
      result = await Navigator.push<PlaceResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MapLocationPickerPage(
            initialLocation: _userLocation,
            title: 'Seleccionar origen',
          ),
        ),
      );
    }
    if (!mounted || result == null) return;
    setState(() => _origin = result);
  }

  Future<void> _pickDestination() async {
    final method = await _showMethodSheet('Seleccionar destino');
    if (!mounted || method == null) return;
    PlaceResult? result;
    if (method == 'search') {
      result = await Navigator.push<PlaceResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MapSearchPage(
            currentLocation: _userLocation,
            searchMode: SearchMode.destination,
          ),
        ),
      );
    } else {
      result = await Navigator.push<PlaceResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MapLocationPickerPage(
            initialLocation: _userLocation,
            title: 'Seleccionar destino',
          ),
        ),
      );
    }
    if (!mounted || result == null) return;
    setState(() => _destination = result);
  }

  void _search() {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;
    context.read<TripPlannerBloc>().add(SearchTripOptions(
          userId: _userId,
          origin: origin.latLng,
          destination: destination.latLng,
          originName: origin.name,
          destinationName: destination.name,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Programar Viaje',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFC12F),
          labelColor: const Color(0xFFFFC12F),
          unselectedLabelColor:
              colorScheme.onSurface.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Buscar ruta'),
            Tab(text: 'Mis planes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SearchTab(
            origin: _origin,
            destination: _destination,
            isDark: isDark,
            onPickOrigin: _pickOrigin,
            onPickDestination: _pickDestination,
            onSearch: _search,
            userId: _userId,
            rescheduleId: widget.tripToReschedule?.id,
          ),
          _MyPlansTab(userId: _userId),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search tab
// ─────────────────────────────────────────────────────────────────────────────

class _SearchTab extends StatelessWidget {
  final PlaceResult? origin;
  final PlaceResult? destination;
  final bool isDark;
  final VoidCallback onPickOrigin;
  final VoidCallback onPickDestination;
  final VoidCallback onSearch;
  final String userId;
  final String? rescheduleId;

  const _SearchTab({
    required this.origin,
    required this.destination,
    required this.isDark,
    required this.onPickOrigin,
    required this.onPickDestination,
    required this.onSearch,
    required this.userId,
    this.rescheduleId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // ── Location pickers ──
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              _LocationPicker(
                icon: Icons.radio_button_checked,
                iconColor: Colors.green,
                hint: 'Origen',
                value: origin?.name,
                onTap: onPickOrigin,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              _LocationPicker(
                icon: Icons.location_on,
                iconColor: Colors.red,
                hint: 'Destino',
                value: destination?.name,
                onTap: onPickDestination,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (origin != null && destination != null)
                      ? onSearch
                      : null,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(
                    'Buscar rutas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC12F),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Results ──
        Expanded(
          child: BlocConsumer<TripPlannerBloc, TripPlannerState>(
            listener: (context, state) {
              if (state is TripPlanSaved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plan guardado en "Mis planes"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is TripPlannerLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFFFC12F)),
                      SizedBox(height: 12),
                      Text('Buscando rutas...'),
                    ],
                  ),
                );
              }
              if (state is TripSearchEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route,
                          size: 56,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text(
                        'No se encontraron rutas\npara ese trayecto',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              if (state is TripSearchResults) {
                return _ResultsList(
                  options: state.options,
                  userId: userId,
                  rescheduleId: rescheduleId,
                );
              }
              if (state is TripPlannerError) {
                return Center(child: Text(state.message));
              }
              // Initial state
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Elige origen y destino\npara buscar rutas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _LocationPicker({
    required this.icon,
    required this.iconColor,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<PlannedTrip> options;
  final String userId;
  final String? rescheduleId;

  const _ResultsList(
      {required this.options, required this.userId, this.rescheduleId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: options.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _TripOptionCard(
        trip: options[i],
        userId: userId,
        rescheduleId: rescheduleId,
      ),
    );
  }
}

class _TripOptionCard extends StatelessWidget {
  final PlannedTrip trip;
  final String userId;
  final String? rescheduleId;

  const _TripOptionCard(
      {required this.trip, required this.userId, this.rescheduleId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route icons
                Column(
                  children: [
                    for (final leg in trip.legs) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC12F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_bus,
                                size: 12, color: Colors.black),
                            const SizedBox(width: 3),
                            Text(
                              leg.routeRef.isNotEmpty
                                  ? leg.routeRef
                                  : leg.routeName,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      if (leg != trip.legs.last)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Icon(Icons.transfer_within_a_station,
                              size: 14,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.routesSummary,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.totalMinutes} min  •  '
                        '${trip.totalDistanceKm.toStringAsFixed(1)} km  •  '
                        'Bs ${trip.totalCostBs.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (trip.legs.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${trip.legs.length} tramos · 1 transbordo',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFFFC12F)
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.08)),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    final tripToSave = rescheduleId != null
                        ? trip.copyWith(id: rescheduleId)
                        : trip;
                    context
                        .read<TripPlannerBloc>()
                        .add(SaveTripPlan(tripToSave));
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Color(0xFFFFC12F)),
                  ),
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: colorScheme.onSurface.withValues(alpha: 0.08)),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanDetallePage(
                        trip: trip,
                        userId: userId,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Elegir',
                    style: TextStyle(
                        color: Color(0xFFFFC12F),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Plans tab
// ─────────────────────────────────────────────────────────────────────────────

class _MyPlansTab extends StatefulWidget {
  final String userId;
  const _MyPlansTab({required this.userId});

  @override
  State<_MyPlansTab> createState() => _MyPlansTabState();
}

class _MyPlansTabState extends State<_MyPlansTab> {
  @override
  void initState() {
    super.initState();
    context.read<TripPlannerBloc>().add(LoadMyPlans(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      buildWhen: (prev, curr) =>
          curr is MyPlansLoaded ||
          curr is TripPlannerLoading ||
          curr is TripPlannerError,
      builder: (context, state) {
        if (state is TripPlannerLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)));
        }
        if (state is TripPlannerError) {
          return Center(child: Text(state.message));
        }
        if (state is MyPlansLoaded) {
          if (state.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 56,
                      color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no tienes planes guardados.\nBusca una ruta y guárdala.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.plans.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _SavedPlanCard(
              trip: state.plans[i],
              userId: widget.userId,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  final PlannedTrip trip;
  final String userId;

  const _SavedPlanCard({required this.trip, required this.userId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: trip.isCompleted
            ? Border.all(color: Colors.green.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC12F),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    trip.isCompleted
                        ? Icons.check_circle_outline
                        : Icons.route,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.routesSummary,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.originName} → ${trip.destinationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.totalMinutes} min • Bs ${trip.totalCostBs.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trip.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Completado',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.08)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    context.read<TripPlannerBloc>().add(
                        DeleteTripPlan(userId, trip.id));
                  },
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  label: const Text('Eliminar',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: colorScheme.onSurface.withValues(alpha: 0.08)),
              Expanded(
                child: TextButton.icon(
                  onPressed: trip.isCompleted
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlanificarViajePage(tripToReschedule: trip),
                            ),
                          ),
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    size: 16,
                    color: trip.isCompleted
                        ? colorScheme.onSurface.withValues(alpha: 0.3)
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  label: Text(
                    'Reprogramar',
                    style: TextStyle(
                      fontSize: 12,
                      color: trip.isCompleted
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: colorScheme.onSurface.withValues(alpha: 0.08)),
              Expanded(
                child: TextButton.icon(
                  onPressed: trip.isCompleted
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlanDetallePage(
                                trip: trip,
                                userId: userId,
                              ),
                            ),
                          ),
                  icon: Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: trip.isCompleted
                        ? colorScheme.onSurface.withValues(alpha: 0.3)
                        : const Color(0xFFFFC12F),
                  ),
                  label: Text(
                    'Iniciar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: trip.isCompleted
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : const Color(0xFFFFC12F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
