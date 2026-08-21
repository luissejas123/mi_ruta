import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mi_ruta/core/di/dependency_injection.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mi_ruta/features/auth/presentation/bloc/auth_state.dart';
import 'package:mi_ruta/features/driver/domain/services/driver_income_service.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_bloc.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_event.dart';
import 'package:mi_ruta/features/driver/presentation/bloc/driver_income_state.dart';
import 'package:mi_ruta/features/user/presentation/widgets/transaction_card.dart';

class HistorialIngresosPage extends StatelessWidget {
  const HistorialIngresosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final driverId = authState is AuthLoaded ? authState.user.uid : '';
        return DriverIncomeBloc(service: getIt<DriverIncomeService>())
          ..add(LoadDriverIncome(driverId));
      },
      child: const _HistorialIngresosView(),
    );
  }
}

class _HistorialIngresosView extends StatelessWidget {
  const _HistorialIngresosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Historial de ingresos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<DriverIncomeBloc, DriverIncomeState>(
        builder: (context, state) {
          if (state is DriverIncomeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC12F)),
            );
          }
          if (state is DriverIncomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          if (state is DriverIncomeLoaded) {
            if (state.entries.isEmpty) return const _EmptyState();
            return Column(
              children: [
                _TotalIncomeHeader(total: state.totalIncome),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: state.entries.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final entry = state.entries[i];
                      return TransactionCard(
                        icon: Icons.payments_outlined,
                        title: 'Pago recibido',
                        subtitle: 'Viaje ${entry.tripId}',
                        amount: '+Bs. ${entry.amount.toStringAsFixed(2)}',
                        date: entry.date,
                        amountColor: Colors.green.shade700,
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TotalIncomeHeader extends StatelessWidget {
  final double total;
  const _TotalIncomeHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC12F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total de ingresos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bs. ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes ingresos registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus ingresos aparecerán aquí\ncuando cobres un viaje por QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
