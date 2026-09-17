import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/demo/demo_constants.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_event.dart';
import 'package:mi_ruta/features/auth/presentation/pages/iniciar_sesion_page.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/tariff_bloc.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/tariff_event.dart';
import 'package:mi_ruta/features/presidente/presentation/bloc/tariff_state.dart';

/// Panel de entrada del presidente: tarifas por km de su línea (RQ-121).
///
/// Hoy usa `kStaticDemoRouteRef` como "su línea" — no existe todavía un
/// campo que ligue un presidente real a una línea específica en `users`;
/// cuando se defina, reemplazar por ese valor.
class PresidenteHomePage extends StatelessWidget {
  const PresidenteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TariffBloc>()
        ..add(const LoadTariff(kStaticDemoRouteRef)),
      child: const _PresidenteHomeView(),
    );
  }
}

class _PresidenteHomeView extends StatefulWidget {
  const _PresidenteHomeView();

  @override
  State<_PresidenteHomeView> createState() => _PresidenteHomeViewState();
}

class _PresidenteHomeViewState extends State<_PresidenteHomeView> {
  static const _amarillo = Color(0xFFFFC12F);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _previewPricePerKm => double.tryParse(_controller.text) ?? 0;

  void _save() {
    final price = double.tryParse(_controller.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio por km válido.')),
      );
      return;
    }
    context.read<TariffBloc>().add(SaveTariffRequested(
          routeRef: kStaticDemoRouteRef,
          pricePerKmBs: price,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas de mi línea',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const IniciarSesionPage()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TariffBloc, TariffState>(
        listener: (context, state) {
          if (state is TariffLoaded) {
            if (state.tariff != null &&
                _controller.text != state.tariff!.pricePerKmBs.toString()) {
              _controller.text = state.tariff!.pricePerKmBs.toStringAsFixed(2);
            }
            if (state.justSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarifa guardada.')),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is TariffLoading || state is TariffInitial) {
            return const Center(
                child: CircularProgressIndicator(color: _amarillo));
          }
          if (state is TariffError) {
            return Center(child: Text(state.message));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Línea $kStaticDemoRouteRef',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Precio por km (Bs)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vista previa',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                      const SizedBox(height: 6),
                      Text(
                        'Con esta tarifa, un tramo de 5 km costaría '
                        '${(_previewPricePerKm * 5).toStringAsFixed(2)} Bs',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amarillo,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Guardar tarifa',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
