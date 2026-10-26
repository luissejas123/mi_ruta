import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/pages/consulta_pasajeros_transportados_page.dart';
import 'package:mi_ruta/features/admin/presentation/pages/reportes_operativos_page.dart';
import 'package:mi_ruta/features/admin/presentation/widgets/shared_date_filter.dart';

const _amarillo = Color(0xFFFFC12F);

/// Modelo de datos con las métricas consolidadas del administrador.
class AdminMetricsData {
  final int totalTrips;
  final int completedTrips;
  final int inProgressTrips;
  final int cancelledTrips;
  final double totalRevenue;
  final int totalVehicles;
  final int unitsInService;
  final int approvedUnits;
  final int pendingUnits;
  final int rejectedUnits;
  final int totalPassengers;
  final int totalDrivers;
  final int totalTicketers;
  final int totalAdmins;
  final int activeAccounts;
  final int blockedAccounts;

  const AdminMetricsData({
    required this.totalTrips,
    required this.completedTrips,
    required this.inProgressTrips,
    required this.cancelledTrips,
    required this.totalRevenue,
    required this.totalVehicles,
    required this.unitsInService,
    required this.approvedUnits,
    required this.pendingUnits,
    required this.rejectedUnits,
    required this.totalPassengers,
    required this.totalDrivers,
    required this.totalTicketers,
    required this.totalAdmins,
    required this.activeAccounts,
    required this.blockedAccounts,
  });

  double get completionRate =>
      totalTrips > 0 ? (completedTrips / totalTrips) * 100 : 0.0;
}

/// Pantalla de métricas simples del administrador (OBS8).
/// Muestra indicadores clave del sistema gobernados por el filtro de fechas compartido.
class AdminMetricasPage extends StatefulWidget {
  const AdminMetricasPage({super.key});

  @override
  State<AdminMetricasPage> createState() => _AdminMetricasPageState();
}

class _AdminMetricasPageState extends State<AdminMetricasPage> {
  late DateTime _from;
  late DateTime _to;
  late Future<AdminMetricsData> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _from = DateTime.now().subtract(const Duration(days: 7));
    _to = DateTime.now();
    _metricsFuture = _loadMetrics();
  }

  Future<AdminMetricsData> _loadMetrics() async {
    final fromDate = DateTime(_from.year, _from.month, _from.day);
    final toDate = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);

    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('trips').get(const GetOptions(source: Source.server)),
      firestore.collection('users').get(const GetOptions(source: Source.server)),
      firestore.collection('vehicles').get(const GetOptions(source: Source.server)),
    ]);

    final tripDocs = results[0].docs;
    final userDocs = results[1].docs;
    final vehicleDocs = results[2].docs;

    int totalTrips = 0;
    int completedTrips = 0;
    int inProgressTrips = 0;
    int cancelledTrips = 0;
    double totalRevenue = 0.0;

    for (final doc in tripDocs) {
      final data = doc.data();
      final rawDate = data['date'] ??
          data['created_at'] ??
          data['createdAt'] ??
          data['timestamp'] ??
          data['start_time'] ??
          data['startTime'];

      if (rawDate != null) {
        DateTime? tripDate;
        if (rawDate is Timestamp) {
          tripDate = rawDate.toDate();
        } else if (rawDate is DateTime) {
          tripDate = rawDate;
        } else {
          tripDate = DateTime.tryParse(rawDate.toString());
        }

        if (tripDate != null) {
          if (tripDate.isBefore(fromDate) || tripDate.isAfter(toDate)) {
            continue;
          }
        }
      }

      totalTrips++;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'completed' || status == 'finalizado' || status == 'completado') {
        completedTrips++;
      } else if (status == 'cancelled' || status == 'cancelado') {
        cancelledTrips++;
      } else {
        inProgressTrips++;
      }

      final fareRaw = data['total_fare'] ?? data['fare'] ?? data['price'] ?? data['monto'];
      if (fareRaw is num) {
        totalRevenue += fareRaw.toDouble();
      } else if (fareRaw != null) {
        totalRevenue += double.tryParse(fareRaw.toString()) ?? 0.0;
      }
    }

    int totalPassengers = 0;
    int totalDrivers = 0;
    int totalTicketers = 0;
    int totalAdmins = 0;
    int activeAccounts = 0;
    int blockedAccounts = 0;

    for (final doc in userDocs) {
      final data = doc.data();
      final role = (data['user_type'] ?? data['userType'] ?? data['role'] ?? 'passenger')
          .toString()
          .toLowerCase();

      if (role == 'driver' || role == 'chofer') {
        totalDrivers++;
      } else if (role == 'tickeador' || role == 'ticketing') {
        totalTicketers++;
      } else if (role == 'admin' ||
          role == 'administrador' ||
          role == 'presidente' ||
          role == 'dirigente') {
        totalAdmins++;
      } else {
        totalPassengers++;
      }

      final active = data['is_active'] ?? data['isActive'] ?? true;
      if (active == false) {
        blockedAccounts++;
      } else {
        activeAccounts++;
      }
    }

    int unitsInService = 0;
    int approvedUnits = 0;
    int pendingUnits = 0;
    int rejectedUnits = 0;

    for (final doc in vehicleDocs) {
      final data = doc.data();
      final inService = data['in_service'] ?? data['inService'];
      if (inService == true) {
        unitsInService++;
      }

      final status = (data['status'] ?? data['approval_status'] ?? '').toString().toLowerCase();
      if (status == 'approved' || status == 'aprobado') {
        approvedUnits++;
      } else if (status == 'rejected' || status == 'rechazado') {
        rejectedUnits++;
      } else {
        pendingUnits++;
      }
    }

    return AdminMetricsData(
      totalTrips: totalTrips,
      completedTrips: completedTrips,
      inProgressTrips: inProgressTrips,
      cancelledTrips: cancelledTrips,
      totalRevenue: totalRevenue,
      totalVehicles: vehicleDocs.length,
      unitsInService: unitsInService,
      approvedUnits: approvedUnits,
      pendingUnits: pendingUnits,
      rejectedUnits: rejectedUnits,
      totalPassengers: totalPassengers,
      totalDrivers: totalDrivers,
      totalTicketers: totalTicketers,
      totalAdmins: totalAdmins,
      activeAccounts: activeAccounts,
      blockedAccounts: blockedAccounts,
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
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
  }

  void _applyDateFilter() {
    if (_to.isBefore(_from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha "hasta" no puede ser anterior a "desde".'),
        ),
      );
      return;
    }
    setState(() {
      _metricsFuture = _loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas del Administrador'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _metricsFuture = _loadMetrics();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _amarillo,
        onRefresh: () async {
          setState(() {
            _metricsFuture = _loadMetrics();
          });
          await _metricsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SharedDateFilter(
              from: _from,
              to: _to,
              onPickDate: (isFrom) => _pickDate(isFrom: isFrom),
              onApply: _applyDateFilter,
              title: 'Período de métricas',
            ),
            const SizedBox(height: 16),
            FutureBuilder<AdminMetricsData>(
              future: _metricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: _amarillo),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Error al cargar las métricas: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _metricsFuture = _loadMetrics();
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiCard(data),
                    const SizedBox(height: 16),
                    _buildFleetCard(data),
                    const SizedBox(height: 16),
                    _buildUsersCard(data),
                    const SizedBox(height: 16),
                    _buildQuickLinksCard(context),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(AdminMetricsData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights, color: Color(0xFFD49A00)),
                    SizedBox(width: 8),
                    Text(
                      'Operación en el período',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _amarillo.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.completionRate.toStringAsFixed(1)}% efectividad',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total viajes',
                    value: '${data.totalTrips}',
                    icon: Icons.directions_bus,
                    color: Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Completados',
                    value: '${data.completedTrips}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'En tránsito',
                    value: '${data.inProgressTrips}',
                    icon: Icons.pending_outlined,
                    color: Colors.orange.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Cancelados',
                    value: '${data.cancelledTrips}',
                    icon: Icons.cancel_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (data.totalRevenue > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recaudación estimada en período',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            'Bs. ${data.totalRevenue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFleetCard(AdminMetricsData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.commute, color: Color(0xFFD49A00)),
                SizedBox(width: 8),
                Text(
                  'Parque automotor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'En servicio',
                    value: '${data.unitsInService}',
                    icon: Icons.traffic,
                    color: Colors.teal.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Aprobadas',
                    value: '${data.approvedUnits}',
                    icon: Icons.verified_outlined,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'En revisión',
                    value: '${data.pendingUnits}',
                    icon: Icons.hourglass_top,
                    color: Colors.amber.shade800,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Rechazadas',
                    value: '${data.rejectedUnits}',
                    icon: Icons.block,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersCard(AdminMetricsData data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_alt_outlined, color: Color(0xFFD49A00)),
                SizedBox(width: 8),
                Text(
                  'Comunidad de usuarios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Pasajeros',
                    value: '${data.totalPassengers}',
                    icon: Icons.person_outline,
                    color: Colors.indigo.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Choferes',
                    value: '${data.totalDrivers}',
                    icon: Icons.airline_seat_recline_normal,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Tickeadores',
                    value: '${data.totalTicketers}',
                    icon: Icons.confirmation_number_outlined,
                    color: Colors.brown.shade700,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Bloqueados',
                    value: '${data.blockedAccounts}',
                    icon: Icons.lock_person_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportes complementarios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amarillo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assessment_outlined, color: Colors.black87),
              ),
              title: const Text('Reportes operativos', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ver detalle por chofer, calificaciones y flota'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportesOperativosPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _amarillo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups_outlined, color: Colors.black87),
              ),
              title: const Text('Pasajeros transportados', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Consulta por ruta y rango de fechas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: getIt<TransportedPassengersBloc>(),
                      child: const ConsultaPasajerosTransportadosPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
