import 'package:flutter/material.dart';
import 'package:mi_ruta/features/user/data/datasources/gtfs_routes_datasource.dart';
import 'package:mi_ruta/features/user/domain/entities/place_result.dart';
import 'package:mi_ruta/features/user/domain/services/route_finder_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/ruta_linea_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/route_map_view.dart';
import 'package:mi_ruta/features/user/presentation/widgets/rutas_seleccion_body.dart';

class RutasSeleccionPage extends StatefulWidget {
  final PlaceResult? destination;

  const RutasSeleccionPage({super.key, this.destination});

  @override
  State<RutasSeleccionPage> createState() => _RutasSeleccionPageState();
}

class _RutasSeleccionPageState extends State<RutasSeleccionPage> {
  final _datasource = GtfsRoutesDatasource();
  List<RouteMatch> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    if (widget.destination == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final routes = await _datasource.fetchRoutes();
      if (!mounted) return;
      final matches = RouteFinderService.findNearby(
        widget.destination!.latLng,
        routes,
        maxResults: 999,
        maxDistanceMeters: 2000,
      );
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar rutas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Fondo blanco consistente
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rutas disponibles',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.destination?.name ?? 'Destino',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ✅ Guard para destination null
              if (widget.destination != null)
                RouteMapView(
                  title: widget.destination!.name,
                  initialPosition: widget.destination!.latLng,
                ),
              const SizedBox(height: 16),
              Expanded(
                child: RutasSeleccionBody(
                  isLoading: _isLoading,
                  error: _error,
                  matches: _matches,
                  onRetry: _loadRoutes,
                  onRouteTap: (match) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RutaLineaPage(
                        route: match.route,
                        destination: widget.destination!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) => navigateBottomNav(context, index),
      ),
    );
  }
}