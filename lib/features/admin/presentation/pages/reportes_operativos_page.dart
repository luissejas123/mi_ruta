import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final role = authState is AuthLoaded
            ? authState.user.role.trim().toLowerCase()
            : '';
        final canAccess = {
          'admin',
          'administrador',
          'dirigente',
          'presidente',
        }.contains(role);

        if (!canAccess) {
          return const Scaffold(
            body: Center(
              child: Text('No tienes permisos para ver este panel.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Panel de dirigencia',
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
                      'Reporte operativo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _SummaryCard(
                          icon: Icons.directions_bus,
                          label: 'Unidades en servicio',
                          value: report.unitsInService,
                        ),
                        _SummaryCard(
                          icon: Icons.check_circle_outline,
                          label: 'Unidades aprobadas',
                          value: report.approvedUnits,
                        ),
                        _SummaryCard(
                          icon: Icons.more_horiz,
                          label: 'Unidades en revisión',
                          value: report.unitsUnderReview,
                        ),
                        _SummaryCard(
                          icon: Icons.cancel_outlined,
                          label: 'Unidades rechazadas',
                          value: report.rejectedUnits,
                        ),
                        _SummaryCard(
                          icon: Icons.groups_outlined,
                          label: 'Choferes registrados',
                          value: report.totalDrivers,
                        ),
                        _SummaryCard(
                          icon: Icons.groups,
                          label: 'Pasajeros registrados',
                          value: report.registeredPassengers,
                        ),
                        _SummaryCard(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Tickeadores',
                          value: report.registeredTicketers,
                        ),
                        _SummaryCard(
                          icon: Icons.block,
                          label: 'Cuentas bloqueadas',
                          value: report.blockedAccounts,
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
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0E7D9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.black54),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
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
