import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_income_service.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_service_state.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_home_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/driver_rutas_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/historial_ingresos_page.dart';
import 'package:mi_ruta/features/driver/presentation/pages/rendimiento_page.dart';
import 'package:mi_ruta/features/driver/presentation/widgets/charge_section.dart';
import 'package:mi_ruta/features/user/presentation/widgets/bottom_nav_router.dart';
import 'package:mi_ruta/features/user/presentation/widgets/custom_bottom_nav.dart';

const _amarillo = Color(0xFFFFC12F);

/// Billetera del chofer (Figma "2.2 Billetera") — antes la pestaña
/// "Billetera" del chofer era literalmente `WalletPage`, la del pasajero
/// (recargar/pagar viaje/beneficios, que no le aplican a un chofer). Esta
/// es de ingresos: MOVIMIENTOS/RENDIMIENTO ya existían como pantallas
/// propias, MOSTRAR QR/ACTUALIZAR QR reutilizan el flujo de cobro por
/// transacción que ya funciona en Inicio (no es un QR fijo/personal nuevo:
/// eso sería una función de pagos aparte, fuera de alcance aquí).
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
          create: (_) => DriverIncomeBloc(service: getIt<DriverIncomeService>())
            ..add(LoadDriverIncome(uid)),
        ),
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
          child: BlocBuilder<DriverOperationsBloc, DriverOperationsState>(
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
              BlocBuilder<DriverIncomeBloc, DriverIncomeState>(
                builder: (context, state) {
                  final total = state is DriverIncomeLoaded ? state.totalIncome : 0.0;
                  return Material(
                    color: _amarillo,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      // Antes esta tarjeta solo mostraba el total y no
                      // llevaba a ningún lado — el historial con filtros
                      // (HistorialIngresosPage) ya existía, solo faltaba
                      // este acceso directo desde el total.
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistorialIngresosPage()),
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
                  MaterialPageRoute(builder: (_) => const HistorialIngresosPage()),
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
                  icon: Icons.refresh,
                  label: 'ACTUALIZAR QR',
                  onTap: () {
                    final bloc = context.read<DriverOperationsBloc>();
                    final state = bloc.state;
                    if (state is DriverOperationsLoaded && state.activeChargeQr != null) {
                      bloc.add(const ClearTripCharge());
                    }
                    _showQrSheet(context, bloc);
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
