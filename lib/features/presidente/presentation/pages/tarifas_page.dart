import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/routes/domain/entities/fare_bracket.dart';
import 'package:mi_ruta/features/routes/domain/entities/route_entity.dart';
import 'package:mi_ruta/features/routes/domain/services/route_service.dart';
import 'package:mi_ruta/features/routes/domain/services/tariff_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// Panel de tarifas por distancia del presidente (Bloque 2, paso 2 de
/// docs/PLAN_SEGURIDAD_TARIFAS_GPS.md). Un presidente puede gestionar más
/// de una línea (`presidente_info.managed_lines`) — si tiene solo una, va
/// directo al formulario; si tiene varias, primero elige el GRUPO de
/// líneas al que aplicar la misma tarifa de una sola vez (no una por una,
/// seguimiento QA 2026-09-15).
class TarifasPage extends StatelessWidget {
  const TarifasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final lineIds = authState is AuthLoaded ? authState.user.managedLines : const <String>[];
    final uid = authState is AuthLoaded ? authState.user.uid : '';

    if (lineIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tarifas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Todavía no tienes una línea asignada. Pide al administrador que te asigne una en "Asignar línea a presidente".',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (lineIds.length == 1) {
      return _TariffFormPage(routeRefs: lineIds, updatedBy: uid);
    }

    return _LinesGroupPickerPage(lineIds: lineIds, updatedBy: uid);
  }
}

/// Elige el grupo de líneas (una o más) al que se le va a aplicar la misma
/// tarifa — mismo patrón de selección múltiple que ya usa
/// AsignarLineasPresidentePage (admin → presidente) para consistencia.
class _LinesGroupPickerPage extends StatefulWidget {
  final List<String> lineIds;
  final String updatedBy;

  const _LinesGroupPickerPage({required this.lineIds, required this.updatedBy});

  @override
  State<_LinesGroupPickerPage> createState() => _LinesGroupPickerPageState();
}

class _LinesGroupPickerPageState extends State<_LinesGroupPickerPage> {
  final Set<String> _selected = {};

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selected
          ..clear()
          ..addAll(widget.lineIds);
      } else {
        _selected.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.lineIds.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Tarifas — elige tus líneas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecciona una o más líneas para aplicarles la misma tarifa.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                TextButton(
                  onPressed: () => _toggleAll(!allSelected),
                  child: Text(allSelected ? 'Ninguna' : 'Todas'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.lineIds.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final ref = widget.lineIds[i];
                return CheckboxListTile(
                  value: _selected.contains(ref),
                  title: Text('Línea $ref'),
                  activeColor: _amarillo,
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(ref);
                    } else {
                      _selected.remove(ref);
                    }
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _TariffFormPage(
                              routeRefs: _selected.toList(),
                              updatedBy: widget.updatedBy,
                            ),
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amarillo,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _selected.isEmpty
                      ? 'Selecciona al menos una línea'
                      : 'Continuar (${_selected.length} línea${_selected.length == 1 ? '' : 's'})',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffFormPage extends StatefulWidget {
  final List<String> routeRefs;
  final String updatedBy;

  const _TariffFormPage({required this.routeRefs, required this.updatedBy});

  bool get isGroup => routeRefs.length > 1;

  @override
  State<_TariffFormPage> createState() => _TariffFormPageState();
}

class _TariffFormPageState extends State<_TariffFormPage> {
  final _maxKm1Ctrl = TextEditingController();
  final _fare1Ctrl = TextEditingController();
  final _maxKm2Ctrl = TextEditingController();
  final _fare2Ctrl = TextEditingController();
  final _fare3Ctrl = TextEditingController();

  RouteEntity? _route;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maxKm1Ctrl.dispose();
    _fare1Ctrl.dispose();
    _maxKm2Ctrl.dispose();
    _fare2Ctrl.dispose();
    _fare3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Para un grupo de varias líneas no hay una sola tarifa existente que
      // mostrar de referencia (podrían tener tarifas distintas hoy) — el
      // formulario arranca en blanco y guardar reemplaza la tarifa de TODAS
      // las líneas seleccionadas por igual.
      RouteEntity? route;
      if (!widget.isGroup) {
        route = await getIt<RouteService>().getRouteByRef(widget.routeRefs.first);
        final tariff = await getIt<TariffService>().getTariff(widget.routeRefs.first);
        if (tariff != null && tariff.brackets.length == 3) {
          _maxKm1Ctrl.text = _fmt(tariff.brackets[0].maxKm);
          _fare1Ctrl.text = _fmt(tariff.brackets[0].fare);
          _maxKm2Ctrl.text = _fmt(tariff.brackets[1].maxKm);
          _fare2Ctrl.text = _fmt(tariff.brackets[1].fare);
          _fare3Ctrl.text = _fmt(tariff.brackets[2].fare);
        }
      }
      if (!mounted) return;
      setState(() {
        _route = route;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la tarifa: $e';
        _loading = false;
      });
    }
  }

  String _fmt(double? value) => value == null ? '' : value.toString();

  Future<void> _save() async {
    final maxKm1 = double.tryParse(_maxKm1Ctrl.text.trim());
    final fare1 = double.tryParse(_fare1Ctrl.text.trim());
    final maxKm2 = double.tryParse(_maxKm2Ctrl.text.trim());
    final fare2 = double.tryParse(_fare2Ctrl.text.trim());
    final fare3 = double.tryParse(_fare3Ctrl.text.trim());

    if (maxKm1 == null || fare1 == null || maxKm2 == null || fare2 == null || fare3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos con números válidos.')),
      );
      return;
    }
    if (maxKm1 <= 0 || maxKm2 <= maxKm1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los kilómetros deben ser positivos y crecientes (tramo 1 < tramo 2).')),
      );
      return;
    }
    if (fare1 <= 0 || fare2 <= 0 || fare3 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las tarifas deben ser mayores a cero.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await getIt<TariffService>().setTariffForLines(
        routeRefs: widget.routeRefs,
        brackets: [
          FareBracket(maxKm: maxKm1, fare: fare1),
          FareBracket(maxKm: maxKm2, fare: fare2),
          FareBracket(maxKm: null, fare: fare3),
        ],
        updatedBy: widget.updatedBy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isGroup
                ? 'Tarifa guardada para ${widget.routeRefs.length} líneas.'
                : 'Tarifa guardada.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isGroup
              ? 'Tarifas · ${widget.routeRefs.length} líneas'
              : 'Tarifas · Línea ${widget.routeRefs.first}',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amarillo))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isGroup) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.routeRefs
                              .map((ref) => Chip(label: Text('Línea $ref')))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Esto reemplazará la tarifa actual de las líneas seleccionadas por la misma tarifa.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (_route != null)
                        Text(_route!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Define hasta qué distancia se cobra cada tarifa. El último tramo aplica para cualquier distancia mayor.',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 20),
                      _BracketRow(
                        label: 'Tramo 1 — hasta',
                        maxKmController: _maxKm1Ctrl,
                        fareController: _fare1Ctrl,
                      ),
                      const SizedBox(height: 16),
                      _BracketRow(
                        label: 'Tramo 2 — hasta',
                        maxKmController: _maxKm2Ctrl,
                        fareController: _fare2Ctrl,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Tramo 3 — el resto', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _fare3Ctrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$'))],
                              decoration: const InputDecoration(labelText: 'Bs.', isDense: true, border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amarillo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                widget.isGroup ? 'Guardar tarifa para el grupo' : 'Guardar tarifa',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _BracketRow extends StatelessWidget {
  final String label;
  final TextEditingController maxKmController;
  final TextEditingController fareController;

  const _BracketRow({
    required this.label,
    required this.maxKmController,
    required this.fareController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: TextField(
            controller: maxKmController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$'))],
            decoration: const InputDecoration(labelText: 'km', isDense: true, border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: fareController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$'))],
            decoration: const InputDecoration(labelText: 'Bs.', isDense: true, border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }
}
