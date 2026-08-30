import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/core/theme/theme_cubit.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/switch_profile_button.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/station_log_entity.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/vehicle_entity.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_bloc.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_event.dart';
import 'package:mi_ruta/features/tickeador/presentation/bloc/tickeador_state.dart';
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
class TickeadorHomePage extends StatefulWidget {
  const TickeadorHomePage({super.key});

  @override
  State<TickeadorHomePage> createState() => _TickeadorHomePageState();
}

class _TickeadorHomePageState extends State<TickeadorHomePage> {
  static const _amarillo = Color(0xFFFFC12F);

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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required IconData icon,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? _amarillo.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _amarillo : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? _amarillo : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              mode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.grey.shade900 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleEntity vehicle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amarillo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amarillo, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: _amarillo, size: 28),
              const SizedBox(width: 8),
              Text(
                vehicle.vehicleId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVehicleRow('Tipo', vehicle.vehicleType),
          _buildVehicleRow('Línea', vehicle.lineNumber),
          _buildVehicleRow('Número interno', vehicle.internalNumber),
          _buildVehicleRow(
            'Marca/Modelo',
            '${vehicle.brand} ${vehicle.model}'.trim(),
          ),
          _buildVehicleRow('Capacidad', '${vehicle.passengerCapacity} pasajeros'),
          _buildVehicleRow('Estado', vehicle.status),
        ],
      ),
    );
  }

  Widget _buildVehicleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLogType(String logType) {
    return logType == 'departure' ? 'Salida' : 'Llegada';
  }

  String _formatTimestamp(DateTime ts) {
    final local = ts.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildActividadItem(StationLogEntity log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            log.logType == 'departure'
                ? Icons.login
                : Icons.logout,
            color: log.logType == 'departure'
                ? Colors.green.shade700
                : Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.vehiclePlate} · Línea ${log.lineId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatLogType(log.logType)} · ${log.stationName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  // ── CAMBIAR A MODO ──
                  _buildSectionTitle('CAMBIAR A MODO'),
                  Row(
                    children: [
                      _buildModeCard(
                        mode: 'Usuario',
                        icon: Icons.person_outline,
                        isActive: false,
                      ),
                      const SizedBox(width: 12),
                      _buildModeCard(
                        mode: 'Chofer',
                        icon: Icons.directions_bus_outlined,
                        isActive: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El modo Tickeador está activo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  // ── Estación asignada ──
                  _buildSectionTitle('MI ESTACIÓN'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _amarillo,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estación asignada',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stationName ?? 'No asignada',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BUSCAR VEHÍCULO POR PLACA ──
                  _buildSectionTitle('BUSCAR VEHÍCULO POR PLACA'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _placaController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Ej: 2341-ABC',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isBusy ? null : _buscarVehiculo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Buscar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Área del vehículo
                  if (state is VehicleFound)
                    _buildVehicleCard(state.vehicle)
                  else if (state is VehicleNotFound)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'Vehículo no encontrado',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Busca un vehículo por placa para ver su información',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Botones Marcar salida / llegada
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (isBusy || _selectedVehicle == null)
                              ? null
                              : _marcarSalida,
                          icon: const Icon(Icons.login),
                          label: const Text('Marcar salida'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amarillo,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (isBusy || _selectedVehicle == null)
                              ? null
                              : _marcarLlegada,
                          icon: const Icon(Icons.logout),
                          label: const Text('Marcar llegada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── ACTIVIDAD RECIENTE ──
                  _buildSectionTitle('ACTIVIDAD RECIENTE'),
                  if (state is ActividadLoaded && state.logs.isNotEmpty)
                    ...state.logs.map(_buildActividadItem)
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay actividad registrada todavía',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () {
                              if (_uid != null) {
                                _tickeadorBloc.add(
                                  CargarActividadEvent(tickeadorId: _uid!),
                                );
                              }
                            },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver Historial'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amarillo,
                        foregroundColor: Colors.black,
                      ),
                    ),
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
