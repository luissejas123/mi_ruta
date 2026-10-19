import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/tickeador/domain/entities/tickeador_payments_report.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_report_export_service.dart';
import 'package:mi_ruta/features/tickeador/domain/services/tickeador_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// Reporte de auditoría de cobros para el tickeador (Obs. 9 del cliente):
/// NO es dinero que el tickeador haya aceptado — el tickeador solo valida
/// recargas de billetera ("Revisar recargas pendientes"), nunca cobra
/// pasajes — es una consulta de solo lectura sobre lo que de verdad se
/// cobró en las unidades que pasaron por SU ESTACIÓN (el tickeador no
/// filtra por línea/ruta), para auditarlo contra lo que vio pasar.
/// Filtrable por rango de fechas, con descarga en PDF/Excel.
class ReporteTickeadorPage extends StatefulWidget {
  const ReporteTickeadorPage({super.key});

  @override
  State<ReporteTickeadorPage> createState() => _ReporteTickeadorPageState();
}

class _ReporteTickeadorPageState extends State<ReporteTickeadorPage> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  Future<TickeadorPaymentsReportEntity>? _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TickeadorPaymentsReportEntity> _load() async {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthLoaded ? authState.user.uid : '';
    // Rango inclusivo de todo el día final.
    final to = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);
    final from = DateTime(_from.year, _from.month, _from.day);
    return getIt<TickeadorService>().getPaymentsReport(tickeadorId: uid, from: from, to: to);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    _reload();
  }

  Future<void> _export(TickeadorPaymentsReportEntity report, {required bool excel}) async {
    setState(() => _exporting = true);
    try {
      final service = getIt<TickeadorReportExportService>();
      final file = excel ? await service.saveExcel(report) : await service.savePdf(report);
      await service.share(file, subject: 'Reporte de cobros - Mi Ruta');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el reporte: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Reporte de cobros',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: FutureBuilder<TickeadorPaymentsReportEntity>(
        future: _future,
        builder: (context, snapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auditoría de lo cobrado en las unidades que pasaron por tu estación — no '
                  'es dinero que hayas recibido vos, es una consulta para verificar contra '
                  'lo que viste pasar.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: true),
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text('Desde ${_fmt(_from)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: false),
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text('Hasta ${_fmt(_to)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(color: _amarillo)),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text('No se pudo cargar el reporte: ${snapshot.error}'),
                  )
                else ...[
                  _buildReport(snapshot.data!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReport(TickeadorPaymentsReportEntity report) {
    if (report.vehicleIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No se registraron vehículos en tu estación en este rango de fechas — marca '
          'salida/llegada de alguna unidad para poder generar este reporte.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total cobrado',
                value: 'Bs. ${report.totalAmount.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(label: 'Viajes pagados', value: '${report.totalTrips}'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (report.byVehicle.isNotEmpty) ...[
          const Text('Por unidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...report.byVehicle.map(
            (v) => _ReportRow(
              title: v.routeName.isNotEmpty ? '${v.vehicleId} · ${v.routeName}' : v.vehicleId,
              subtitle: '${v.trips} viajes',
              value: 'Bs. ${v.amount.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (report.byDay.isNotEmpty) ...[
          const Text('Por día', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...report.byDay.map((d) => _DayBreakdown(day: d, formatDate: _fmt)),
          const SizedBox(height: 20),
        ],
        if (report.totalTrips == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No hay cobros registrados en este rango de fechas para las unidades vistas '
              'en tu estación.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting || report.totalTrips == 0
                    ? null
                    : () => _export(report, excel: false),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting || report.totalTrips == 0
                    ? null
                    : () => _export(report, excel: true),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Excel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DayBreakdown extends StatelessWidget {
  final DailyPaymentsSummary day;
  final String Function(DateTime) formatDate;
  const _DayBreakdown({required this.day, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDate(day.day),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 8),
          ...day.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.passengerName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(e.vehicleId,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Text('Bs. ${e.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total del día', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Bs. ${day.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  const _ReportRow({required this.title, required this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        ],
      ),
    );
  }
}
