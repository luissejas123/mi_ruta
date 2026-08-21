import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_ruta/features/admin/data/datasources/operational_report_datasource.dart';
import 'package:mi_ruta/features/admin/domain/entities/operational_report.dart';
import 'package:mi_ruta/features/admin/domain/services/operational_report_service.dart';

class ReportesOperativosPage extends StatefulWidget {
  const ReportesOperativosPage({super.key});

  @override
  State<ReportesOperativosPage> createState() => _ReportesOperativosPageState();
}

class _ReportesOperativosPageState extends State<ReportesOperativosPage> {
  late final OperationalReportService _service;
  late Future<OperationalReport> _report;

  @override
  void initState() {
    super.initState();
    _service = OperationalReportService(
      datasource: OperationalReportDatasource(
        firestore: FirebaseFirestore.instance,
      ),
    );
    _report = _service.getReport();
  }

  Future<void> _refresh() async {
    setState(() => _report = _service.getReport());
    await _report;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<OperationalReport>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(onRetry: _refresh);
          }
          final report = snapshot.data!;
          return RefreshIndicator(
            color: const Color(0xFFFFC12F),
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  'Resumen de desempeño',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SummaryCard(
                      label: 'TOTAL',
                      value: report.totalDrivers,
                      color: const Color(0xFFFFC12F),
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'SUSPENDIDOS',
                      value: report.suspendedDrivers.length,
                      color: const Color(0xFFFFE5E5),
                      valueColor: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    _SummaryCard(
                      label: 'DESTACADOS',
                      value: report.featuredDrivers.length,
                      color: const Color(0xFFE2F7EF),
                      valueColor: Colors.green.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DriverSection(
                  title: 'Choferes suspendidos',
                  count: report.suspendedDrivers.length,
                  drivers: report.suspendedDrivers,
                  emptyText: 'No hay choferes suspendidos.',
                  accent: Colors.red.shade700,
                ),
                const SizedBox(height: 14),
                _DriverSection(
                  title: 'Buen desempeño',
                  count: report.featuredDrivers.length,
                  drivers: report.featuredDrivers,
                  emptyText: 'No hay choferes destacados todavía.',
                  accent: Colors.green.shade700,
                  showRating: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color? valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.black.withValues(alpha: .55),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
          const Text('Activos', style: TextStyle(fontSize: 9)),
        ],
      ),
    ),
  );
}

class _DriverSection extends StatelessWidget {
  final String title;
  final int count;
  final List<DriverOperationalStatus> drivers;
  final String emptyText;
  final Color accent;
  final bool showRating;

  const _DriverSection({
    required this.title,
    required this.count,
    required this.drivers,
    required this.emptyText,
    required this.accent,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC12F),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5AD13)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (drivers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: const TextStyle(fontSize: 12)),
          )
        else
          ...drivers
              .take(6)
              .map(
                (driver) => _DriverRow(
                  driver: driver,
                  accent: accent,
                  showRating: showRating,
                ),
              ),
      ],
    ),
  );
}

class _DriverRow extends StatelessWidget {
  final DriverOperationalStatus driver;
  final Color accent;
  final bool showRating;

  const _DriverRow({
    required this.driver,
    required this.accent,
    required this.showRating,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.black.withValues(alpha: .12)),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.circle, size: 6, color: accent),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            driver.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Text(
          driver.line.isEmpty ? 'Sin línea' : 'Línea ${driver.line}',
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(width: 8),
        Text(
          showRating ? '★ ${driver.rating.toStringAsFixed(1)}' : 'Suspendido',
          style: TextStyle(
            fontSize: 9,
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        const Text('No se pudieron cargar los reportes.'),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
