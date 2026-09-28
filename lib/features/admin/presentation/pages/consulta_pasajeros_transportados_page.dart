import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_bloc.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_event.dart';
import 'package:mi_ruta/features/admin/presentation/bloc/transported_passengers_state.dart';
import 'package:mi_ruta/features/admin/domain/entities/transported_passengers_report.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';

const _amarillo = Color(0xFFFFC12F);

/// Consulta de pasajeros transportados por ruta y rango de fechas, leyendo
/// el historial real de viajes (`trip_history/*/trips`), no datos
/// inventados. Requiere `TransportedPassengersBloc` provisto por quien
/// navega a esta página (ver `perfil_page.dart`).
class ConsultaPasajerosTransportadosPage extends StatefulWidget {
  const ConsultaPasajerosTransportadosPage({super.key});

  @override
  State<ConsultaPasajerosTransportadosPage> createState() =>
      _ConsultaPasajerosTransportadosPageState();
}

class _ConsultaPasajerosTransportadosPageState
    extends State<ConsultaPasajerosTransportadosPage> {
  RouteEntity? _selectedRoute;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<TransportedPassengersBloc>().add(
      const LoadRoutesForQueryEvent(),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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

  void _buscar() {
    final route = _selectedRoute;
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ruta primero')),
      );
      return;
    }
    if (_to.isBefore(_from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha "hasta" no puede ser anterior a "desde"'),
        ),
      );
      return;
    }
    context.read<TransportedPassengersBloc>().add(
      SearchTransportedPassengersEvent(
        routeRef: route.ref,
        from: DateTime(_from.year, _from.month, _from.day),
        // Fin de día para que el rango incluya viajes de todo el "hasta".
        to: DateTime(_to.year, _to.month, _to.day, 23, 59, 59),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasajeros Transportados'),
      ),
      body: BlocBuilder<TransportedPassengersBloc, TransportedPassengersState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ruta',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (state.isLoadingRoutes)
                  const Center(child: CircularProgressIndicator(color: _amarillo))
                else if (state.routesError != null)
                  Text(
                    'No se pudieron cargar las rutas: ${state.routesError}',
                    style: const TextStyle(color: Colors.red),
                  )
                else
                  DropdownButtonFormField<RouteEntity>(
                    initialValue: _selectedRoute,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona una ruta',
                    ),
                    items: state.routes
                        .map(
                          (route) => DropdownMenuItem(
                            value: route,
                            child: Text('${route.ref} — ${route.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (route) =>
                        setState(() => _selectedRoute = route),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Rango de fechas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: true),
                        child: Text('Desde: ${_formatDate(_from)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: false),
                        child: Text('Hasta: ${_formatDate(_to)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.isSearching ? null : _buscar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amarillo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: state.isSearching
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Buscar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                if (state.searchError != null)
                  Text(
                    'Error al consultar: ${state.searchError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                if (state.report != null) _ReportSummary(report: state.report!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final TransportedPassengersReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruta ${report.routeRef}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _StatRow(label: 'Viajes registrados', value: '${report.totalTrips}'),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Pasajeros únicos transportados',
              value: '${report.uniquePassengers}',
            ),
            if (report.totalTrips > 0) ...[
              const SizedBox(height: 20),
              const Text(
                'Viajes por día',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _TripsPerDayChart(data: report.tripsPerDay),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripsPerDayChart extends StatelessWidget {
  const _TripsPerDayChart({required this.data});

  final List<DailyTripsCount> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    // Con muchos días en el rango, una etiqueta por día amontona el eje —
    // se saltean etiquetas manteniendo legible el rango.
    final labelStep = (data.length / 6).ceil().clamp(1, data.length);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.shade700,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = data[group.x.toInt()];
              return BarTooltipItem(
                '${_shortDate(point.day)}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: '${point.count} viaje(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= data.length ||
                    index % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _shortDate(data[index].day),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].count.toDouble(),
                  color: _amarillo,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
