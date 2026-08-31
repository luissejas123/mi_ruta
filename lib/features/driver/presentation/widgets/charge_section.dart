import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_operations_state.dart';

const _amarillo = Color(0xFFFFC12F);

/// Cobro de viaje por QR (generar/limpiar). Extraído de `driver_home_page.dart`
/// para reusarlo también en `DriverWalletPage` ("MOSTRAR QR"/"ACTUALIZAR QR"
/// del Figma de billetera del chofer) — un solo flujo de cobro, no dos.
class ChargeSection extends StatefulWidget {
  final DriverOperationsLoaded state;

  const ChargeSection({super.key, required this.state});

  @override
  State<ChargeSection> createState() => _ChargeSectionState();
}

class _ChargeSectionState extends State<ChargeSection> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return state.activeChargeQr != null
        ? Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(data: state.activeChargeQr!, size: 200),
              ),
              const SizedBox(height: 10),
              Text(
                'Monto: Bs. ${state.activeChargeAmount?.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'El pasajero escanea este código para pagar.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      context.read<DriverOperationsBloc>().add(const ClearTripCharge()),
                  child: const Text('Cerrar cobro'),
                ),
              ),
            ],
          )
        : Column(
            children: [
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto (Bs.)',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isBusy
                      ? null
                      : () {
                          final amount = double.tryParse(_amountCtrl.text.trim());
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa un monto válido.')),
                            );
                            return;
                          }
                          context.read<DriverOperationsBloc>().add(GenerateTripCharge(amount));
                        },
                  icon: const Icon(Icons.qr_code, color: Colors.black),
                  label: const Text(
                    'Generar código de cobro',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: _amarillo),
                ),
              ),
            ],
          );
  }
}
