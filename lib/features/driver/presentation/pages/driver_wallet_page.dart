import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/rendimiento_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/unit_qr_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/charge_section.dart';
import 'package:mi_ruta/features/user/domain/services/wallet_service.dart';
import 'package:mi_ruta/features/user/presentation/pages/ganancias_chofer_page.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

/// Billetera del chofer (Figma "2.2 Billetera") — antes la pestaña
/// "Billetera" del chofer era literalmente `WalletPage`, la del pasajero
/// (recargar/pagar viaje/beneficios, que no le aplican a un chofer). Esta
/// es de ingresos: MOVIMIENTOS/RENDIMIENTO ya existían como pantallas
/// propias. MOSTRAR QR reutiliza el flujo de cobro por transacción que ya
/// funciona en Inicio; ACTUALIZAR QR abre "QR de mi unidad"
/// (`UnitQrPage`) — un código FIJO por unidad para imprimir y colgar en el
/// vehículo (Figma "5.4.1 Cobrar Viaje"), no el mismo QR temporal de cobro.
class DriverWalletPage extends StatelessWidget {
  final String? role;

  const DriverWalletPage({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DriverServiceBloc(service: getIt<DriverService>())
            ..add(LoadAssignedVehicle(uid)),
        ),
        BlocProvider(
          create: (_) => DriverOperationsBloc(service: getIt<DriverService>()),
        ),
      ],
      child: _DriverWalletView(role: role),
    );
  }
}

class _DriverWalletView extends StatelessWidget {
  final String? role;

  const _DriverWalletView({required this.role});

  void _showQrSheet(BuildContext context, DriverOperationsBloc operationsBloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: operationsBloc,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: BlocBuilder<DriverServiceBloc, DriverServiceState>(
            builder: (context, serviceState) {
              // Sin unidad (o sin aprobar todavía), DriverOperationsBloc
              // nunca recibe LoadDriverOperations — antes esto se quedaba
              // girando para siempre en vez de decir por qué.
              if (serviceState is DriverServiceNoVehicle) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Registra y activa tu unidad primero para poder cobrar por QR.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return BlocBuilder<DriverOperationsBloc, DriverOperationsState>(
                builder: (context, state) {
                  if (state is! DriverOperationsLoaded) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(color: _amarillo)),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Cobro de viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 14),
                      ChargeSection(state: state),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DriverServiceBloc, DriverServiceState>(
          listenWhen: (previous, current) =>
              current is DriverServiceLoaded && previous is! DriverServiceLoaded,
          listener: (context, state) {
            if (state is DriverServiceLoaded) {
              context.read<DriverOperationsBloc>().add(LoadDriverOperations(state.vehicle));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text('Billetera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total vía WalletService.getDriverEarnings — NO
              // DriverIncomeService/HistorialIngresosPage: esa consulta usa
              // `.orderBy()` y exige un índice compuesto que no está creado
              // todavía en Firestore (por eso mostraba Bs. 0.00 en vez del
              // total real). getDriverEarnings ordena en memoria, sin
              // índice, igual que el resto de fallbacks del proyecto — y ya
              // es lo que usa GananciasChoferPage, así que consolidamos en
              // un solo mecanismo en vez de mantener dos.
              FutureBuilder<Map<String, dynamic>>(
                future: getIt<WalletService>().getDriverEarnings(() {
                  final authState = context.read<AuthBloc>().state;
                  return authState is AuthLoaded ? authState.user.uid : '';
                }()),
                builder: (context, snapshot) {
                  final total = (snapshot.data?['total_ganancia'] as num?)?.toDouble() ?? 0.0;
                  return Material(
                    color: _amarillo,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GananciasChoferPage()),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INGRESOS',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bs. ${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _WalletActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'MOVIMIENTOS',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GananciasChoferPage()),
                ),
              ),
              const SizedBox(height: 10),
              _WalletActionButton(
                icon: Icons.insights_outlined,
                label: 'RENDIMIENTO',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RendimientoPage()),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) => _WalletActionButton(
                  icon: Icons.qr_code_2,
                  label: 'MOSTRAR QR',
                  onTap: () => _showQrSheet(context, context.read<DriverOperationsBloc>()),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) => _WalletActionButton(
                  icon: Icons.qr_code_scanner_outlined,
                  label: 'ACTUALIZAR QR',
                  onTap: () {
                    final serviceState = context.read<DriverServiceBloc>().state;
                    final vehicle = serviceState is DriverServiceLoaded
                        ? serviceState.vehicle
                        : serviceState is DriverServiceError
                            ? serviceState.vehicle
                            : null;
                    if (vehicle == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registra y activa tu unidad primero.')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UnitQrPage(vehicle: vehicle)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 1,
          onTap: (index) => navigateBottomNav(
            context,
            index,
            homeBuilder: (_) => DriverHomePage(roleOverride: role),
            walletBuilder: (_) => DriverWalletPage(role: role),
            routesBuilder: (_) => DriverRutasPage(role: role),
          ),
        ),
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _amarillo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
