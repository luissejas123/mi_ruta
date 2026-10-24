import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/stops/domain/entities/bus_stop_entity.dart';
import 'package:mi_ruta/features/stops/domain/services/bus_stop_service.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';

class ParadaDetallePage extends StatefulWidget {
  final BusStopEntity stop;
  const ParadaDetallePage({super.key, required this.stop});

  @override
  State<ParadaDetallePage> createState() => _ParadaDetallePageState();
}

class _ParadaDetallePageState extends State<ParadaDetallePage> {
  Map<String, String> _routeNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteNames();
  }

  Future<void> _loadRouteNames() async {
    final names = await getIt<BusStopService>().enrichRouteRefs(
      widget.stop.routeRefs,
    );
    if (!mounted) return;
    setState(() {
      _routeNames = names;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stop = widget.stop;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Información de parada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteMapView(
              title: stop.name,
              initialPosition: LatLng(stop.lat, stop.lng),
            ),
            const SizedBox(height: 16),
            Text(
              stop.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${stop.lat.toStringAsFixed(6)}, ${stop.lng.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Líneas que pasan por aquí',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
                ),
              )
            else if (stop.routeRefs.isEmpty)
              Text(
                'No hay líneas registradas para esta parada.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              )
            else
              Column(
                children: stop.routeRefs
                    .map((ref) => _RouteRow(ref: ref, name: _routeNames[ref]))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String ref;
  final String? name;
  const _RouteRow({required this.ref, this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC12F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Línea $ref',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (name != null && name!.isNotEmpty)
                  Text(
                    name!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
