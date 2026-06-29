import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mi_ruta/core/theme/map_styles.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';

import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/mi_ruta_state.dart';
import 'package:mi_ruta/features/user/presentation/pages/perfil_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/rutas_inicio_page.dart';
import 'package:mi_ruta/features/user/presentation/pages/wallet_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_action_fabs.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_confirm_panel.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_pin_overlay.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_search_header.dart';
import 'package:mi_ruta/features/user/presentation/widgets/map_status_card.dart';

class MiRutaScreen extends StatefulWidget {
  const MiRutaScreen({super.key});

  @override
  State<MiRutaScreen> createState() => _MiRutaScreenState();
}

class _MiRutaScreenState extends State<MiRutaScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    context.read<MiRutaBloc>().add(const MiRutaLocationRequested());
  }

  @override
  void dispose() {
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
    context.read<MiRutaBloc>().add(const MiRutaPinModeToggled());
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
      // ✅ Navega al perfil real con AuthBloc disponible
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const PerfilPage(),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
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
    };
  }

  Widget _buildMap(MiRutaState state, bool isDark) {
    if (state.myLocationLatLng == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
      );
    }
    return GoogleMap(
      style: isDark ? MapStyles.dark : null,
      initialCameraPosition: CameraPosition(
        target: state.myLocationLatLng!,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onCameraMove: (pos) {
        context.read<MiRutaBloc>().add(MiRutaCameraMoved(pos.target));
      },
      onCameraIdle: () {
        context.read<MiRutaBloc>().add(const MiRutaCameraIdle());
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
        if (state.cameraUpdateLocation != null && _mapController != null) {
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