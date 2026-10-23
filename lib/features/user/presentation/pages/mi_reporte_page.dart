import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/presentation/bloc/passenger_report_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/passenger_report_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/passenger_report_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/period_filter_button.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_report.dart';

/// Pantalla de Observación 7: Reporte del Pasajero.
///
/// Muestra un reporte resumido de los movimientos del pasajero filtrado por período,
/// con tarjetas de resumen y cobros por ruta.
class MiReportePage extends StatefulWidget {
  const MiReportePage({super.key});

  @override
  State<MiReportePage> createState() => _MiReportePageState();
}

class _MiReportePageState extends State<MiReportePage> {
  ReportPeriod _selectedPeriod = ReportPeriod.todos;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    // Mismo criterio que MovimientosPage: el uid sale del AuthBloc global.
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : '';
  }

  /// Carga el reporte del período seleccionado. Recibe el `context` de
  /// debajo del BlocProvider (el de este State está por encima).
  void _load(BuildContext blocContext) {
    blocContext.read<PassengerReportBLoC>().add(
          LoadPassengerReportEvent(userId: _userId, period: _selectedPeriod),
        );
  }

  /// Un reporte sin ningún movimiento se trata como "sin datos".
  bool _isEmpty(PassengerReport report) =>
      report.routeCharges.isEmpty &&
      report.totalIncome == 0 &&
      report.totalPayments == 0 &&
      report.totalRefunds == 0;

  String _formatCurrency(double amount) => 'Bs. ${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    // BLoC propio de la pantalla (registerFactory): se crea al abrirla y se
    // cierra al salir. Carga "Todos" apenas se abre.
    return BlocProvider<PassengerReportBLoC>(
      create: (_) => getIt<PassengerReportBLoC>()
        ..add(
          LoadPassengerReportEvent(userId: _userId, period: _selectedPeriod),
        ),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'MI REPORTE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // El filtro queda visible en todos los estados (carga, vacío,
              // error) para poder cambiar de período desde cualquiera.
              Builder(builder: _buildPeriodFilter),
              const SizedBox(height: 20),
              Expanded(
                child: BlocBuilder<PassengerReportBLoC, PassengerReportState>(
                  builder: (context, state) {
                    if (state is PassengerReportInitial ||
                        state is PassengerReportLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFC12F),
                        ),
                      );
                    }

                    if (state is PassengerReportError) {
                      return _buildErrorState(context, state.message);
                    }

                    if (state is PassengerReportEmpty) {
                      return _buildEmptyState(context, state.period);
                    }

                    if (state is PassengerReportLoaded) {
                      final report = state.report;
                      if (_isEmpty(report)) {
                        return _buildEmptyState(context, report.period);
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjetas de resumen
                            _buildSummaryCards(context, report),

                            const SizedBox(height: 32),

                            // Cobros por ruta
                            _buildRouteChargesSection(context, report),

                            const SizedBox(height: 32),

                            // Badge de cancelaciones
                            _buildCancellationBadge(context, report),
                          ],
                        ),
                      );
                    }

                    return const Center(child: Text('Estado inesperado'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: ReportPeriod.values.length,
        itemBuilder: (_, index) {
          final period = ReportPeriod.values[index];

          return PeriodFilterButton(
            label: period.label,
            isSelected: _selectedPeriod == period,
            onTap: () {
              setState(() => _selectedPeriod = period);
              _load(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, PassengerReport report) {
    return Row(
      children: [
        // Tarjeta Ingresos
        Expanded(
          child: _SummaryCard(
            label: 'Ingresos',
            amount: _formatCurrency(report.totalIncome),
            icon: Icons.trending_up,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        // Tarjeta Pagos de viajes
        Expanded(
          child: _SummaryCard(
            label: 'Pagos Viaje',
            amount: _formatCurrency(report.totalPayments),
            icon: Icons.directions_bus,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        // Tarjeta Reembolsos
        Expanded(
          child: _SummaryCard(
            label: 'Reembolsos',
            amount: _formatCurrency(report.totalRefunds),
            icon: Icons.undo,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteChargesSection(
      BuildContext context, PassengerReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cobros por ruta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        report.routeCharges.isEmpty
            ? const _EmptyRouteCharges()
            : Column(
                children: report.routeCharges.map((charge) => _RouteChargeTile(
                  routeName: charge.routeName,
                  tripCount: charge.tripCount,
                  totalAmount: charge.totalAmount,
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildCancellationBadge(
      BuildContext context, PassengerReport report) {
    return Chip(
      label: Text('${report.cancellationCount} cancelaciones'),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            // Reintenta el mismo período que estaba elegido.
            onPressed: () => _load(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC12F),
              foregroundColor: Colors.black,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReportPeriod period) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Color(0xFFFFC12F)),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes viajes en este período',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${period.label} vacío',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de resumen con ícono y monto.
class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ficha para cada cobro por ruta.
class _RouteChargeTile extends StatelessWidget {
  final String routeName;
  final int tripCount;
  final double totalAmount;

  const _RouteChargeTile({
    required this.routeName,
    required this.tripCount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          // `routeName` ya viene como "Línea 101" desde el repositorio.
          routeName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${tripCount} viajes',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          _formatAmount(totalAmount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFC12F),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) => 'Bs. ${amount.toStringAsFixed(2)}';
}

/// Ficha vacía cuando no hay cobros por ruta.
class _EmptyRouteCharges extends StatelessWidget {
  const _EmptyRouteCharges();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Sin cobros por ruta',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}
