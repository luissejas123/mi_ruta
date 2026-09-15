import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_bloc.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_event.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_state.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/revision_recargas_page.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_actividad_section.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_mode_switch_section.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_station_section.dart';
import 'package:mi_ruta/features/tickeador/presentation/pages/tickeador_vehicle_search_section.dart';
import 'package:mi_ruta/features/user/presentation/pages/qr_scanner_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/logout_button.dart' show confirmLogout;

/// Pantalla principal del Modo Tickeador (RQ-78).
///
/// ETAPA 2: operación real con Firestore:
/// - Lee tickeador_info (estación asignada)
/// - Busca vehículo por placa
/// - Marca salida / llegada (station_logs)
/// - Muestra actividad reciente
///
/// El armado visual de cada bloque vive en su propio archivo dentro de esta
/// misma carpeta (tickeador_mode_switch_section.dart, tickeador_station_
/// section.dart, tickeador_vehicle_search_section.dart +
/// tickeador_vehicle_info_card.dart, tickeador_actividad_section.dart +
/// tickeador_actividad_item.dart, tickeador_section_title.dart) — esta clase
/// solo mantiene el estado y la lógica (carga inicial, búsqueda, marcar
/// salida/llegada, escáner QR) y compone esas secciones en `build()`.
class TickeadorHomePage extends StatefulWidget {
  const TickeadorHomePage({super.key});

  @override
  State<TickeadorHomePage> createState() => _TickeadorHomePageState();
}

class _TickeadorHomePageState extends State<TickeadorHomePage> {
  final _placaController = TextEditingController();
  late final TickeadorBloc _tickeadorBloc;

  String? _uid;
  String? _stationName;
  VehicleEntity? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _tickeadorBloc = getIt<TickeadorBloc>();
    _loadInitialData();
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  void _mostrarQRScanner() async {
    final qrCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(),
      ),
    );

    if (qrCode != null && qrCode.isNotEmpty) {
      // Dispara la validación del QR
      _tickeadorBloc.add(ValidateTripQr(qrCode: qrCode));
    }
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthLoaded) {
      _uid = authState.user.uid;
      _tickeadorBloc.add(CargarTickeadorEvent(uid: _uid!));
      _tickeadorBloc.add(CargarActividadEvent(tickeadorId: _uid!));
    }
  }

  void _buscarVehiculo() {
    final placa = _placaController.text.trim();
    if (placa.isEmpty) {
      _showSnack('Ingresa una placa para buscar', isError: true);
      return;
    }
    _tickeadorBloc.add(BuscarVehiculoEvent(placa: placa));
  }

  void _marcarSalida() {
    if (_uid == null) {
      _showSnack('Usuario sin UID. No se puede realizar la operación.',
          isError: true);
      return;
    }
    if (_stationName == null || _stationName!.isEmpty) {
      _showSnack('El tickeador no tiene estación asignada. No se puede registrar.',
          isError: true);
      return;
    }
    if (_selectedVehicle == null) {
      _showSnack('Primero busca un vehículo por placa.', isError: true);
      return;
    }
    _tickeadorBloc.add(
      MarcarSalidaEvent(
        tickeadorId: _uid!,
        stationName: _stationName!,
        vehicle: _selectedVehicle!,
      ),
    );
  }

  void _marcarLlegada() {
    if (_uid == null) {
      _showSnack('Usuario sin UID. No se puede realizar la operación.',
          isError: true);
      return;
    }
    if (_stationName == null || _stationName!.isEmpty) {
      _showSnack('El tickeador no tiene estación asignada. No se puede registrar.',
          isError: true);
      return;
    }
    if (_selectedVehicle == null) {
      _showSnack('Primero busca un vehículo por placa.', isError: true);
      return;
    }
    _tickeadorBloc.add(
      MarcarLlegadaEvent(
        tickeadorId: _uid!,
        stationName: _stationName!,
        vehicle: _selectedVehicle!,
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().state;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Modo Tickeador',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          const SwitchProfileButton(),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Revisar recargas pendientes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RevisionRecargasPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear código QR',
            onPressed: _mostrarQRScanner,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _tickeadorBloc,
        child: BlocConsumer<TickeadorBloc, TickeadorState>(
          listener: (context, state) {
            if (state is TickeadorLoaded) {
              _stationName = state.tickeador?.assignedStation;
            }
            if (state is VehicleFound) {
              _selectedVehicle = state.vehicle;
            }
            if (state is VehicleNotFound) {
              _selectedVehicle = null;
              _showSnack('Vehículo no encontrado', isError: true);
            }
            if (state is StationLogSuccess) {
              _showSnack(state.message);
            }
            if (state is TickeadorError) {
              _showSnack(state.message, isError: true);
            }
          },
          builder: (context, state) {
            final isBusy = state is TickeadorLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TickeadorModeSwitchSection(),
                  TickeadorStationSection(
                    stationName: _stationName,
                    isDarkMode: isDarkMode,
                  ),
                  TickeadorVehicleSearchSection(
                    controller: _placaController,
                    isBusy: isBusy,
                    isDarkMode: isDarkMode,
                    foundVehicle: state is VehicleFound ? state.vehicle : null,
                    notFound: state is VehicleNotFound,
                    hasSelectedVehicle: _selectedVehicle != null,
                    onBuscar: _buscarVehiculo,
                    onMarcarSalida: _marcarSalida,
                    onMarcarLlegada: _marcarLlegada,
                  ),
                  TickeadorActividadSection(
                    logs: state is ActividadLoaded ? state.logs : const [],
                    isDarkMode: isDarkMode,
                    isBusy: isBusy,
                    onVerHistorial: () {
                      if (_uid != null) {
                        _tickeadorBloc.add(
                          CargarActividadEvent(tickeadorId: _uid!),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0, // Tickeador is the first tab (index 0)
        // Sin Billetera ni Rutas (Figma "Modo Tickeador", node 3896-5285):
        // el tickeador no tiene ninguna de las dos — antes el bottom nav
        // compartido las mostraba igual y llevaban a las pantallas del
        // pasajero por error.
        tabs: const [0, 3],
        onTap: (index) {
          navigateBottomNav(
            context,
            index,
            homeBuilder: (_) => const TickeadorHomePage(),
          );
        },
      ),
    );
  }
}
