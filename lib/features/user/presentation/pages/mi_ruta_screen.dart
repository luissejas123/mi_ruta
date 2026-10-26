import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/core/utils/location_icon_painter.dart';
import 'package:mi_ruta/features/driver/data/datasources/live_location_datasource.dart';
import 'package:mi_ruta/features/driver/domain/entities/live_vehicle_location.dart';
import 'package:mi_ruta/features/user/data/datasources/location_datasource.dart';

import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_rol_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_action_fabs.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_status_card.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/services/notification_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/notificaciones_page.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  GoogleMapController? _mapController;
  int _unreadCount = 0;
  BitmapDescriptor? _locationIcon;
  StreamSubscription<Position>? _positionSubscription;

  /// Obs. 2 — último centro de cámara, guardado localmente. Antes cada
  /// cuadro del arrastre del mapa mandaba un evento al BLoC y reconstruía
  /// toda la pantalla (incluido el GoogleMap): eso trababa el mapa.
  LatLng? _lastCameraTarget;

  /// Mapa en tiempo real: unidades en servicio que publican su posición.
  StreamSubscription<List<LiveVehicleLocation>>? _liveVehiclesSub;
  List<LiveVehicleLocation> _liveVehicles = const [];

  @override
  void initState() {
    super.initState();
    context.read<MiRutaBloc>().add(const MiRutaLocationRequested());
    _loadUnreadCount();
    LocationIconPainter.build().then((icon) {
      if (mounted && icon != null) setState(() => _locationIcon = icon);
    });
    // El bloc es singleton (vive toda la app), así que el stream de GPS lo
    // controla esta pantalla mientras está montada — no el bloc — para no
    // seguir rastreando ubicación en segundo plano cuando el usuario está
    // en otra pestaña.
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        context.read<MiRutaBloc>().add(
              MiRutaLiveLocationUpdated(LatLng(position.latitude, position.longitude)),
            );
      },
      // Sin esto, negar el permiso de ubicación (o tenerlo revocado) deja
      // una excepción sin capturar flotando en el stream — no tumba la
      // pantalla, pero sí queda como error no manejado de la app.
      onError: (Object error) {
        debugPrint('[MiRutaScreen] Error en el stream de ubicación: $error');
      },
    );
    _listenLiveVehicles();
  }

  /// Escucha la posición en vivo de las unidades en servicio. Si la regla
  /// de Firestore aún no está desplegada, el error se ignora y el mapa
  /// funciona igual, sin las unidades.
  void _listenLiveVehicles() {
    _liveVehiclesSub = getIt<LiveLocationDatasource>().watch().listen(
      (vehicles) {
        if (!mounted) return;
        final now = DateTime.now();
        setState(() {
          _liveVehicles = vehicles.where((v) => v.isFresh(now)).toList();
        });
      },
      onError: (Object error) {
        debugPrint('[MiRutaScreen] Unidades en vivo no disponibles: $error');
      },
    );
  }

  Future<void> _loadUnreadCount() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      final count = await getIt<NotificationService>()
          .getUnreadCount(authState.user.uid);
      if (mounted) setState(() => _unreadCount = count);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificacionesPage()),
    );
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _liveVehiclesSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _goToMyLocation() {
    context.read<MiRutaBloc>().add(const MiRutaGoToMyLocationRequested());
  }

  Future<void> _onSearchTap() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const RutasInicioPage()),
    );
  }

  void _clearSearch() {
    context.read<MiRutaBloc>().add(const MiRutaClearSearch());
  }

  void _togglePinMode() {
    final bloc = context.read<MiRutaBloc>();
    // Al entrar al modo pin, el BLoC necesita el centro actual de la cámara
    // (ya no se le manda en cada cuadro del arrastre).
    if (!bloc.state.isPinMode && _lastCameraTarget != null) {
      bloc.add(MiRutaCameraMoved(_lastCameraTarget!));
    }
    bloc.add(const MiRutaPinModeToggled());
  }

  void _confirmPinDestination() {
    context.read<MiRutaBloc>().add(const MiRutaPinDestinationConfirmed());
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletPage()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RutasInicioPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const PerfilRolPage(),
          ),
        ),
      );
      return;
    }
    context.read<MiRutaBloc>().add(MiRutaNavTabSelected(index));
  }

  Set<Marker> _buildMarkers(MiRutaState state) {
    return {
      if (state.myLocationLatLng != null)
        Marker(
          markerId: const MarkerId('mi_ubicacion'),
          position: state.myLocationLatLng!,
          // Círculo tipo "punto azul" en vez del pin genérico de Maps —
          // mismo ícono que ya usa la navegación en vivo (LocationIconPainter),
          // con fallback al pin mientras se termina de dibujar.
          icon: _locationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      if (state.destinationLatLng != null)
        Marker(
          markerId: const MarkerId('destino'),
          position: state.destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: state.searchText ?? 'Destino'),
        ),
      for (final v in _liveVehicles)
        Marker(
          markerId: MarkerId('unidad_${v.vehicleId}'),
          position: LatLng(v.latitude, v.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          rotation: v.heading ?? 0,
          flat: v.heading != null,
          infoWindow: InfoWindow(
            title: v.routeName ?? 'Unidad en servicio',
            snippet: 'Placa ${v.vehicleId}',
          ),
        ),
    };
  }

  Widget _buildMap(MiRutaState state, bool isDark) {
    // Obs. 2 — el mapa se dibuja de inmediato (centrado en Cochabamba si
    // todavía no hay ubicación) en vez de dejar la pantalla con un spinner
    // hasta que el GPS responda. Cuando llega la ubicación, el
    // BlocListener mueve la cámara.
    final initialTarget =
        state.myLocationLatLng ?? LocationDatasource.defaultCenter;
    return GoogleMap(
      style: isDark ? MapStyles.dark : null,
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: state.myLocationLatLng != null ? 15 : 13,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        // Si la ubicación llegó antes de que el mapa terminara de crearse,
        // el BlocListener no pudo mover la cámara: se centra acá.
        final location = context.read<MiRutaBloc>().state.myLocationLatLng;
        if (location != null && state.myLocationLatLng == null) {
          controller.moveCamera(CameraUpdate.newLatLngZoom(location, 15));
        }
      },
      onCameraMove: (pos) {
        _lastCameraTarget = pos.target;
        // Solo el modo pin necesita saber que la cámara se mueve (para
        // ocultar la dirección); un evento al empezar alcanza.
        final bloc = context.read<MiRutaBloc>();
        if (bloc.state.isPinMode && !bloc.state.isCameraMoving) {
          bloc.add(MiRutaCameraMoved(pos.target));
        }
      },
      onCameraMoveStarted: () {
        context.read<MiRutaBloc>().add(const MiRutaCameraMoveStarted());
      },
      onCameraIdle: () {
        final bloc = context.read<MiRutaBloc>();
        if (bloc.state.isPinMode && _lastCameraTarget != null) {
          bloc.add(MiRutaCameraMoved(_lastCameraTarget!));
        }
        bloc.add(const MiRutaCameraIdle());
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      markers: state.isPinMode ? const <Marker>{} : _buildMarkers(state),
      zoomControlsEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MiRutaBloc, MiRutaState>(
      listenWhen: (previous, current) =>
          previous.cameraTriggerCount != current.cameraTriggerCount,
      listener: (context, state) {
        // `initState` re-pide la ubicación cada vez que se recrea esta
        // pantalla (pasa siempre que volvés a "Inicio" desde el bottom
        // nav). Como el bloc es singleton y ya tenía una ubicación previa,
        // el mapa aparece interactivo al toque — y si esa nueva ubicación
        // llega mientras el usuario ya está arrastrando el pin para marcar
        // un punto, este auto-jump se lo sacaba de las manos a mitad de
        // camino. En modo pin, el único que debe mover la cámara es el
        // propio arrastre del usuario.
        if (state.cameraUpdateLocation != null &&
            _mapController != null &&
            !state.isPinMode) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(state.cameraUpdateLocation!, 15),
          );
        }
      },
      child: BlocBuilder<MiRutaBloc, MiRutaState>(
        builder: (context, state) {
          final isDark = context.watch<ThemeCubit>().state;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  MapSearchHeader(
                    onSearchTap: _onSearchTap,
                    searchText: state.searchText,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildMap(state, isDark)),
                        if (state.myLocationLatLng == null)
                          const Positioned(
                            top: 12,
                            left: 12,
                            child: _LocatingChip(),
                          ),
                        if (state.isPinMode)
                          MapPinOverlay(
                            isCameraMoving: state.isCameraMoving,
                          ),
                        if (!state.isPinMode)
                          Positioned.fill(
                            child: MapActionFabs(
                              hasDestination:
                                  state.destinationLatLng != null,
                              onMyLocation: _goToMyLocation,
                              onTogglePin: _togglePinMode,
                              onClearSearch: _clearSearch,
                            ),
                          ),
                        if (state.isPinMode)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: MapPinConfirmPanel(
                              isCameraMoving: state.isCameraMoving,
                              address: state.pinAddress,
                              confirmButtonText: 'Confirmar destino',
                              onCancel: _togglePinMode,
                                onConfirm: (state.isCameraMoving ||
                                      state.pinAddress == null)
                                  ? null
                                  : _confirmPinDestination,
                            ),
                          ),
                        if (state.statusText != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 80,
                            child: MapStatusCard(
                              message: state.statusText!,
                            ),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: _openNotifications,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 22,
                                  ),
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: state.selectedIndex,
              onTap: _onNavTap,
            ),
          );
        },
      ),
    );
  }
}

/// Aviso pequeño mientras llega la primera ubicación (el mapa ya se ve).
class _LocatingChip extends StatelessWidget {
  const _LocatingChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Buscando tu ubicación…',
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
