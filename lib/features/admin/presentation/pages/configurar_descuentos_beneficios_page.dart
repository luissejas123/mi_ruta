import 'package:flutter/material.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/user/domain/services/benefit_discount_service.dart';

const _amarillo = Color(0xFFFFC12F);

/// El admin define qué % de descuento corresponde a cada tipo de beneficio
/// aprobado (estudiante/universitario/adulto mayor) — antes un beneficio
/// aprobado no descontaba nada al cobrar el viaje, `RuteNavegacionPage`
/// aplica el mayor % que corresponda a los beneficios activos de la cuenta.
class ConfigurarDescuentosBeneficiosPage extends StatefulWidget {
  const ConfigurarDescuentosBeneficiosPage({super.key});

  @override
  State<ConfigurarDescuentosBeneficiosPage> createState() =>
      _ConfigurarDescuentosBeneficiosPageState();
}

class _ConfigurarDescuentosBeneficiosPageState
    extends State<ConfigurarDescuentosBeneficiosPage> {
  static const _types = ['student', 'university', 'senior'];
  static const _labels = {
    'student': 'Estudiante',
    'university': 'Universitario',
    'senior': 'Adulto mayor',
  };

  final _controllers = {
    for (final type in _types) type: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final discounts = await getIt<BenefitDiscountService>().getDiscounts();
    if (!mounted) return;
    for (final type in _types) {
      final percent = discounts[type] ?? 0.0;
      _controllers[type]!.text = (percent * 100).toStringAsFixed(0);
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final percentByType = <String, double>{};
    for (final type in _types) {
      final raw = double.tryParse(_controllers[type]!.text.trim());
      if (raw == null || raw < 0 || raw > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El % de ${_labels[type]} debe ser un número entre 0 y 100.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
      percentByType[type] = raw / 100;
    }
    setState(() => _saving = true);
    try {
      await getIt<BenefitDiscountService>().setDiscounts(percentByType);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descuentos guardados'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Descuentos de beneficios',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amarillo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '% de descuento que se aplica al cobrar un viaje a un pasajero '
                    'con este beneficio aprobado.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final type in _types) ...[
                    TextField(
                      controller: _controllers[type],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _labels[type],
                        suffixText: '%',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
