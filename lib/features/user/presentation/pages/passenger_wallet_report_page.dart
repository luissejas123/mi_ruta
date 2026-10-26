import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/user/domain/entities/passenger_wallet_report.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_bloc.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_event.dart';
import 'package:mi_ruta/features/user/presentation/bloc/wallet_state.dart';

class PassengerWalletReportPage extends StatefulWidget {
  const PassengerWalletReportPage({super.key});

  @override
  State<PassengerWalletReportPage> createState() =>
      _PassengerWalletReportPageState();
}

class _PassengerWalletReportPageState extends State<PassengerWalletReportPage> {
  static const _yellow = Color(0xFFFFC12F);
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _userId = authState is AuthLoaded ? authState.user.uid : '';
    _loadReport();
  }

  void _loadReport() {
    if (_userId.isNotEmpty) {
      context.read<WalletBloc>().add(LoadPassengerReportEvent(_userId));
    }
  }

  String _formatMoney(double amount) => 'Bs. ${amount.toStringAsFixed(2)}';

  Widget _buildReport(PassengerWalletReport report) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Resumen de tus movimientos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ReportMetric(
              icon: Icons.savings_outlined,
              label: 'Ingresos',
              value: _formatMoney(report.income),
            ),
            _ReportMetric(
              icon: Icons.directions_bus_outlined,
              label: 'Pagos de viajes (${report.paymentCount})',
              value: _formatMoney(report.payments),
            ),
            _ReportMetric(
              icon: Icons.undo,
              label: 'Reembolsos',
              value: _formatMoney(report.refunds),
            ),
            _ReportMetric(
              icon: Icons.cancel_outlined,
              label: 'Cancelaciones',
              value: report.cancellationCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Cobros por ruta',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (report.routeCharges.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Todavía no hay pagos de viaje registrados.'),
            ),
          )
        else
          ...report.routeCharges.map(
            (charge) => Card(
              child: ListTile(
                leading: const Icon(Icons.route_outlined, color: _yellow),
                title: Text(charge.route),
                subtitle: Text(
                  '${charge.paymentCount} ${charge.paymentCount == 1 ? 'pago' : 'pagos'}',
                ),
                trailing: Text(
                  _formatMoney(charge.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Card(
          color: report.isReconciled
              ? Colors.green.withValues(alpha: 0.10)
              : Colors.orange.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      report.isReconciled
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      color: report.isReconciled
                          ? Colors.green.shade800
                          : Colors.deepOrange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.isReconciled
                            ? 'Saldo conciliado'
                            : 'El saldo no coincide con los movimientos',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatMoney(report.income)} − '
                  '${_formatMoney(report.payments)} + '
                  '${_formatMoney(report.refunds)} = '
                  '${_formatMoney(report.calculatedBalance)}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text('Saldo actual: ${_formatMoney(report.currentBalance)}'),
                if (!report.isReconciled) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diferencia: ${_formatMoney(report.reconciliationDifference)}. '
                    'Revisa el historial de movimientos.',
                    style: TextStyle(color: Colors.deepOrange.shade900),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte del pasajero'),
        actions: [
          IconButton(
            tooltip: 'Actualizar reporte',
            onPressed: _loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _userId.isEmpty
          ? const Center(
              child: Text('Inicia sesión para consultar tu reporte.'),
            )
          : BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                if (state is WalletLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PassengerReportLoaded) {
                  return _buildReport(state.report);
                }
                if (state is WalletError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadReport,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: FilledButton(
                    onPressed: _loadReport,
                    child: const Text('Cargar reporte'),
                  ),
                );
              },
            ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  static const _yellow = Color(0xFFFFC12F);

  final IconData icon;
  final String label;
  final String value;

  const _ReportMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _yellow),
              const SizedBox(height: 10),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
